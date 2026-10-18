"""Public-boundary regressions using synthetic data only."""
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import zipfile
import uuid
import os

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('package_files', ROOT / 'scripts/package_files.py')
pkg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pkg)

class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.src = self.base / 'source'
        self.dst = self.base / 'destination'
        self.src.mkdir()
        self.marker = ('private-fixture-' + uuid.uuid4().hex).encode()
        for name in pkg.public_paths(ROOT):
            target = self.src / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)

    def poison(self):
        for name in ['.env', 'corpus/raw.txt', 'cases/private.md', 'DEVLOG.md',
                     'metrics/latest.md', 'references/nested/private.log',
                     'scripts/unknown.txt', 'backup-copy/private.md']:
            p = self.src / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_bytes(self.marker)

    def test_copy_excludes_unknown_nested_and_private_files(self):
        self.poison()
        pkg.copy_public(self.src, self.dst)
        actual = {str(p.relative_to(self.dst)) for p in self.dst.rglob('*') if p.is_file()}
        self.assertEqual(actual, set(pkg.public_paths(ROOT)) | {'MANIFEST.txt'})
        self.assertFalse(any(self.marker in p.read_bytes() for p in self.dst.rglob('*') if p.is_file()))

    def test_install_and_release_exclude_private_files(self):
        self.poison()
        subprocess.run(['bash', str(self.src / 'install.sh'), '--from-local', str(self.dst)], check=True, capture_output=True)
        self.assertFalse((self.dst / 'DEVLOG.md').exists())
        subprocess.run(['bash', str(self.src / 'scripts/release.sh'), '1.7.3', '--dry-run', '--repo', 'example/second-take'], check=True, capture_output=True)
        with zipfile.ZipFile(self.src / 'second-take-latest.zip') as z:
            files = {n.removeprefix('second-take/') for n in z.namelist() if not n.endswith('/')}
            self.assertEqual(files, set(pkg.public_paths(ROOT)) | {'MANIFEST.txt'})
            self.assertEqual(z.read('second-take/MANIFEST.txt').decode().splitlines(), sorted(files))
            self.assertFalse(any(self.marker in z.read(n) for n in z.namelist() if not n.endswith('/')))

    def test_remote_install_and_update_from_release(self):
        self.poison()
        subprocess.run(['bash', str(self.src / 'scripts/release.sh'), '1.7.3', '--dry-run', '--repo', 'example/second-take'], check=True, capture_output=True)
        # A fake downloader serves a local release, exercising extraction + copying
        # without internet or real credentials.
        bindir = self.base / 'bin'; bindir.mkdir()
        curl = bindir / 'curl'
        curl.write_text("""#!/bin/sh
api=0
for arg in "$@"; do
  case "$arg" in *api.github.com*/releases/latest) api=1;; esac
done
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then
    if [ "$api" -eq 1 ]; then printf '{"tag_name":"v1.7.3"}' > "$2"
    else cp "$TEST_ARCHIVE" "$2"; fi
    exit 0
  fi
  shift
done
exit 1
""")

        curl.chmod(0o755)
        env = dict(os.environ, PATH=str(bindir) + os.pathsep + os.environ['PATH'], TEST_ARCHIVE=str(self.src / 'second-take-latest.zip'))
        for script in ['install.sh', 'update.sh']:
            with self.subTest(script=script):
                dest = self.base / script.replace('.sh', '-remote')
                subprocess.run(['bash', str(self.src / script), str(dest)], env=env, check=True, capture_output=True)
                self.assertEqual((dest / 'SKILL.md').read_bytes(), (self.src / 'SKILL.md').read_bytes())
                self.assertTrue((dest / 'references/思维链四标准.md').is_file())
                self.assertFalse((dest / 'corpus').exists())


    def test_missing_latest_release_never_falls_back_to_main(self):
        bindir = self.base / 'api-failure-bin'; bindir.mkdir()
        curl = bindir / 'curl'
        curl.write_text('#!/bin/sh\\nprintf "%s\\n" "$*" >> "$TEST_LOG"\\nexit 22\\n')
        curl.chmod(0o755)
        log = self.base / 'network-requests.log'
        env = dict(os.environ, PATH=str(bindir) + os.pathsep + os.environ['PATH'], TEST_LOG=str(log))
        result = subprocess.run(['bash', str(self.src / 'update.sh'), str(self.dst)],
                                env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.dst.exists())
        self.assertNotIn('refs/heads/main', log.read_text())

    def test_explicit_version_rejects_wrong_archive(self):
        # A valid ZIP from 1.7.3 must not be installed as 1.7.2.
        subprocess.run(['bash', str(self.src / 'scripts/release.sh'), '1.7.3',
                        '--dry-run', '--repo', 'example/second-take'],
                       check=True, capture_output=True)
        bindir = self.base / 'version-bin'; bindir.mkdir()
        curl = bindir / 'curl'
        curl.write_text("""#!/bin/sh
for arg in "$@"; do
  case "$arg" in *codeload.github.com*) exit 22;; esac
done
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-o" ]; then cp "$TEST_ARCHIVE" "$2"; exit 0; fi
  shift
done
exit 22
""")
        curl.chmod(0o755)
        env = dict(os.environ, PATH=str(bindir) + os.pathsep + os.environ['PATH'],
                   TEST_ARCHIVE=str(self.src / 'second-take-latest.zip'))
        result = subprocess.run(['bash', str(self.src / 'install.sh'),
                                 '--version', '1.7.2', str(self.dst)],
                                env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.dst.exists())
        self.assertIn('版本', result.stderr)

    def test_missing_file_aborts_before_write(self):
        (self.src / 'README.md').unlink()
        with self.assertRaises(ValueError): pkg.copy_public(self.src, self.dst)
        self.assertFalse(self.dst.exists())

    def test_source_symlink_rejected(self):
        p = self.src / 'README.md'
        p.unlink(); p.symlink_to(ROOT / 'README.md')
        with self.assertRaises(ValueError): pkg.copy_public(self.src, self.dst)
        self.assertFalse(self.dst.exists())

    def test_destination_symlink_rejected_before_overwrite(self):
        self.dst.mkdir()
        outside = self.base / 'outside'; outside.mkdir()
        (self.dst / 'references').symlink_to(outside, target_is_directory=True)
        with self.assertRaises(ValueError): pkg.copy_public(self.src, self.dst)
        self.assertEqual(list(outside.iterdir()), [])
        self.assertFalse((self.dst / 'SKILL.md').exists())

    def test_destination_root_symlink_rejected_before_overwrite(self):
        outside = self.base / 'outside-root'; outside.mkdir()
        (outside / 'SKILL.md').write_text('do not overwrite')
        self.dst.symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'Symbolic link'):
            pkg.copy_public(self.src, self.dst)
        self.assertEqual((outside / 'SKILL.md').read_text(), 'do not overwrite')
        self.assertEqual([p.name for p in outside.iterdir()], ['SKILL.md'])

    def test_traversal_private_and_duplicate_manifest_rejected(self):
        manifest = self.base / 'list.txt'
        for entry in ['../outside', '/absolute', '.env', 'corpus/raw.txt', 'SKILL.md']:
            with self.subTest(entry=entry):
                manifest.write_text('SKILL.md\n' + entry + '\n')
                with self.assertRaises(ValueError): pkg.public_paths(self.src, manifest)

    def test_legacy_allows_only_new_tools_to_be_missing(self):
        p = self.src / 'SKILL.md'
        p.write_text(p.read_text().replace('version: "1.7.3"', 'version: "1.7.1"'))
        for name in pkg.NEW_IN_172: (self.src / name).unlink()
        pkg.copy_public(self.src, self.dst, allow_legacy=True)
        self.assertTrue((self.dst / 'SKILL.md').exists())
        (self.src / 'README.md').unlink()
        with self.assertRaises(ValueError): pkg.public_paths(self.src, allow_legacy=True)


    def test_readme_maintenance_never_exposes_download_badge(self):
        root = self.base / 'readme-maintenance'
        root.mkdir()
        obsolete = '[![skills.sh](https://img.shields.io/badge/skills.sh-indexed-brightgreen)](https://skills.sh)'
        old_download = '[![Downloads](https://img.shields.io/github/downloads/flashfrogluo/second-take/total?style=flat&logo=github)](https://github.com/flashfrogluo/second-take/releases)'
        for name in ('README.md', 'README_EN.md'):
            (root / name).write_text(obsolete + '\n' + old_download + '\n' +
                '```bash\nnpx skills add flashfrogluo/second-take\n```\n', encoding='utf-8')
        cmd = ['python3', str(ROOT / 'scripts/patch_readme.py'), str(root)]
        subprocess.run(cmd, check=True, capture_output=True)
        once = [(root / name).read_text(encoding='utf-8') for name in ('README.md', 'README_EN.md')]
        self.assertTrue(all('github/downloads' not in body and 'Last commit' in body for body in once))
        subprocess.run(cmd, check=True, capture_output=True)
        self.assertEqual(once, [(root / name).read_text(encoding='utf-8') for name in ('README.md', 'README_EN.md')])


    def test_readme_download_badge_at_end_of_file(self):
        root = self.base / 'readme-eof'; root.mkdir()
        body = '[![Downloads](https://img.shields.io/github/downloads/flashfrogluo/second-take/total?style=flat)](https://github.com/flashfrogluo/second-take/releases)'
        p = root / 'README.md'; p.write_text(body)
        subprocess.run(['python3', str(ROOT / 'scripts/patch_readme.py'), str(root)], check=True, capture_output=True)
        self.assertEqual(p.read_text(), '')

    def test_release_transaction_with_mock_api(self):
        # Synthetic API/git fixtures; these tests do not contact GitHub.
        import json
        bindir = self.base / 'release-bin'; bindir.mkdir()
        fake = r"""#!/usr/bin/env python3
import sys,os,json
from pathlib import Path
a=sys.argv[1:]; scenario=os.environ['RELEASE_CASE']
if Path(sys.argv[0]).name == 'git':
    if a[:2]==['rev-parse','--is-inside-work-tree']: print('true')
    elif a==['rev-parse','HEAD']: print('a'*40)
    elif a[:2]==['ls-remote','origin']: print('a'*40+'\tHEAD')
    elif a[:2]==['ls-remote','--tags'] and scenario=='existing-tag': print('a'*40+'\trefs/tags/v1.7.3')
    sys.exit(0)
method=a[a.index('-X')+1]
with open(os.environ['RELEASE_LOG'],'a') as f:f.write(method+'\n')
if method=='DELETE': sys.exit(0)
if method=='PATCH':
    if scenario=='publish-timeout': sys.exit(28)
    print(json.dumps({'draft':False,'tag_name':'v1.7.3','html_url':'https://github.com/example/second-take/releases/tag/v1.7.3'}));sys.exit(0)
if '--data-binary' in a:
    if scenario=='upload-failure': sys.exit(22)
    size=Path(a[a.index('--data-binary')+1][1:]).stat().st_size
    print(json.dumps({'name':'second-take-latest.zip','state':'uploaded','size':size+(1 if scenario=='wrong-size' else 0),'browser_download_url':'https://github.com/example/asset'}))
else:
    data=json.loads(a[a.index('-d')+1]); assert data['draft'] is True and data['target_commitish']=='a'*40
    print(json.dumps({'id':123,'draft':True,'upload_url':'https://uploads.github.com/repos/example/second-take/releases/123/assets{?name}'}))
"""
        for name in ('curl', 'git'):
            p = bindir / name; p.write_text(fake); p.chmod(0o755)
        cases = {
            'success': (0, ['POST', 'POST', 'PATCH']),
            'upload-failure': (1, ['POST', 'POST', 'DELETE']),
            'wrong-size': (1, ['POST', 'POST', 'DELETE']),
            'publish-timeout': (1, ['POST', 'POST', 'PATCH']),
            'existing-tag': (1, []),
        }
        for case, (failure, expected) in cases.items():
            with self.subTest(case=case):
                log = self.base / (case + '.txt')
                env = dict(os.environ, PATH=str(bindir)+os.pathsep+os.environ['PATH'], GITHUB_TOKEN='synthetic-test-token', RELEASE_CASE=case, RELEASE_LOG=str(log))
                result = subprocess.run(['bash', str(self.src/'scripts/release.sh'), '1.7.3', '--repo', 'example/second-take'], env=env, capture_output=True, text=True)
                self.assertEqual(int(result.returncode != 0), failure, result.stderr)
                self.assertEqual(log.read_text().splitlines() if log.exists() else [], expected)
                self.assertNotIn('synthetic-test-token', result.stdout+result.stderr)
                if case=='publish-timeout': self.assertIn('uncertain', result.stderr)

if __name__ == '__main__': unittest.main()
