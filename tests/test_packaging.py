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
        subprocess.run(['bash', str(self.src / 'scripts/release.sh'), '1.7.2', '--dry-run', '--repo', 'example/second-take'], check=True, capture_output=True)
        with zipfile.ZipFile(self.src / 'second-take-latest.zip') as z:
            files = {n.removeprefix('second-take/') for n in z.namelist() if not n.endswith('/')}
            self.assertEqual(files, set(pkg.public_paths(ROOT)) | {'MANIFEST.txt'})
            self.assertFalse(any(self.marker in z.read(n) for n in z.namelist() if not n.endswith('/')))

    def test_remote_install_and_update_from_release(self):
        self.poison()
        subprocess.run(['bash', str(self.src / 'scripts/release.sh'), '1.7.2', '--dry-run', '--repo', 'example/second-take'], check=True, capture_output=True)
        # A fake downloader serves a local release, exercising extraction + copying
        # without internet or real credentials.
        bindir = self.base / 'bin'; bindir.mkdir()
        curl = bindir / 'curl'
        curl.write_text('#!/bin/sh\nwhile [ "$#" -gt 0 ]; do\n if [ "$1" = "-o" ]; then cp "$TEST_ARCHIVE" "$2"; exit; fi\n shift\ndone\nexit 1\n')
        curl.chmod(0o755)
        env = dict(os.environ, PATH=str(bindir) + os.pathsep + os.environ['PATH'], TEST_ARCHIVE=str(self.src / 'second-take-latest.zip'))
        for script in ['install.sh', 'update.sh']:
            with self.subTest(script=script):
                dest = self.base / script.replace('.sh', '-remote')
                subprocess.run(['bash', str(self.src / script), str(dest)], env=env, check=True, capture_output=True)
                self.assertEqual((dest / 'SKILL.md').read_bytes(), (self.src / 'SKILL.md').read_bytes())
                self.assertTrue((dest / 'references/思维链四标准.md').is_file())
                self.assertFalse((dest / 'corpus').exists())

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

    def test_traversal_private_and_duplicate_manifest_rejected(self):
        manifest = self.base / 'list.txt'
        for entry in ['../outside', '/absolute', '.env', 'corpus/raw.txt', 'SKILL.md']:
            with self.subTest(entry=entry):
                manifest.write_text('SKILL.md\n' + entry + '\n')
                with self.assertRaises(ValueError): pkg.public_paths(self.src, manifest)

    def test_legacy_allows_only_new_tools_to_be_missing(self):
        p = self.src / 'SKILL.md'
        p.write_text(p.read_text().replace('version: "1.7.2"', 'version: "1.7.1"'))
        for name in pkg.NEW_IN_172: (self.src / name).unlink()
        pkg.copy_public(self.src, self.dst, allow_legacy=True)
        self.assertTrue((self.dst / 'SKILL.md').exists())
        (self.src / 'README.md').unlink()
        with self.assertRaises(ValueError): pkg.public_paths(self.src, allow_legacy=True)

if __name__ == '__main__': unittest.main()
