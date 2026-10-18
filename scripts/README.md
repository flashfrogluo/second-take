# 维护脚本

这些脚本服务**维护、发版与统计**，不参与 skill 的质检运行。质检流程本身是纯 Markdown，无依赖。

| 脚本 | 作用 |
|---|---|
| `stats.sh` | 聚合采集影响力数据：星标 / Fork / 关注 / skills.sh 安装量 / Release 下载量，追加历史并算增速 |
| `release.sh` | 校验公开包 → 草稿 Release → 上传及核验 ZIP → 正式发布（不输出下载次数） |
| `install.sh` | 安装：优先从 Release 附件，失败回退 codeload |
| `update.sh` | 更新：直接复用 `install.sh`，避免第二套下载与校验逻辑 |
| `sync-local.sh` | 把远端最新版同步到本地安装副本（codeload 归档 + 自动备份） |
| `push-to-github.sh` | 在独立 Git 工作区按公开清单检查、测试、提交并正常推送 |
| `schedule/` | launchd 定时采集的安装、卸载与任务定义 |
| `patch_readme.py` | 维护 README 的 Star/Watch 引导与最近提交徽章，不增加下载次数展示 |
| `patch_description.py` | 改写 SKILL.md 的 `description`：检索词前置，保留原触发集 |

## 为什么需要这些

三个平台限制决定了它们的形态：

**GitHub 不记录源码包下载量。** `Code → Download ZIP` 与 `codeload` 归档都不计数，只有 **Release 附件**有 `download_count`（[isaacs/github#593](https://github.com/isaacs/github/issues/593) 自 2015 年 open 至今）。所以 `install.sh` 优先走 Release 附件，`release.sh` 负责产出附件。

> ⚠️ **覆盖同名附件会让计数归零**（[badges/shields#10130](https://github.com/badges/shields/issues/10130)）。`release.sh` 因此禁止同名覆盖，每次发版必须用新 tag。

**GitHub Traffic 只有 14 天窗口。** 过期即永久丢失，而「影响力」看的是**增速**不是总数——一周涨 5 个星比三个月攒 20 个星说明力强。`stats.sh` 每次运行追加一行到 `history.jsonl`，`--history` 即可看增速。

**skills.sh 的收录由「一次成功安装」触发。** CLI 安装后上报 `add-skill.vercel.sh/t?event=install&source=<owner/repo>&skills=<name>`，服务端据此建索引并按其周期重爬。所以：

- `stats.sh` 用 `/api/download/<owner>/<repo>/<skill>` 判定收录状态（已收录返回 `200`，未收录 `404`）——搜索接口是模糊匹配，不足为凭
- **不要**提 indexing issue，机器人会回复「No manual reindex request is needed」并关闭
- 索引抓的是**安装那一刻**的元数据，所以改完 description 要**重新安装一次**才会进索引

## 日常用法

```bash
./stats.sh                     # 采集并追加历史
./stats.sh --history           # 看历史与增速（自动定位历史文件）
./stats.sh --no-write          # 只看，不写历史

GITHUB_TOKEN="$(gh auth token)" ./release.sh 1.7.3        # 发版
./release.sh 1.7.3 --dry-run               # 只打包
./release.sh 1.7.3 --notes "自定义说明"     # 覆盖 CHANGELOG 抓取

./sync-local.sh --diff         # 只看本地安装副本与远端的差异
./sync-local.sh                # 同步（自动备份）

./push-to-github.sh --check    # 校验公开清单并读取远端分支
./push-to-github.sh --dry-run  # 看将提交什么
./push-to-github.sh            # 提交
```

`stats.sh` 未设 `GITHUB_TOKEN` 时走匿名 API（每小时 60 次，够用），但读不到 Traffic（访客/克隆）。要读 Traffic 就设 token：

```bash
export GITHUB_TOKEN="$(gh auth token)"   # 请先以安全方式登录 gh CLI
```

## 定时采集

用 macOS 原生 `launchd`，**不是 cron**——cron 自 10.15 起需要 Full Disk Access，容易静默失败；且笔记本休眠时 cron 会跳过任务，而 launchd 会在唤醒后补跑。

```
每天 0 / 6 / 12 / 18 点的第 17 分钟
命令  ~/.agents/skills/second-take/scripts/stats.sh
数据  ~/.local/share/second-take-metrics/history.jsonl
日志  ~/.local/share/second-take-metrics/launchd.{out,err}.log
代理  ~/Library/LaunchAgents/com.flashfrogluo.second-take-stats.plist
```

数据刻意放在仓库外，避免每次采集都在仓库里产生 git 改动。

```bash
./schedule/install-schedule.sh --dry-run   # 演练：只检查前置条件
./schedule/install-schedule.sh             # 安装（会立刻跑一次验证）
./schedule/uninstall-schedule.sh           # 卸载，保留数据
./schedule/uninstall-schedule.sh --purge   # 卸载并删数据

launchctl kickstart -k gui/$(id -u)/com.flashfrogluo.second-take-stats   # 手动触发
launchctl print gui/$(id -u)/com.flashfrogluo.second-take-stats          # 查状态
```

## 已知环境坑

这些是实际踩到过的，写下来省得重复排查：

**归档解压可能丢可执行位。** `sync-local.sh` 与 `install.sh` 走 tar 解压，`scripts/*.sh` 可能没有 `+x`，报 `Permission denied` 时补一次：

```bash
chmod +x ~/.agents/skills/second-take/scripts/*.sh
```

**某些网络环境下 git 传输会失败**，而 API 正常。症状：

```
git ls-remote https://github.com/...  →  Error in the HTTP2 framing layer
                                        （或 Empty reply from server）
```

这是**间歇性**的。`push-to-github.sh` 使用普通 Git 推送；网络失败时保留本地提交，修复网络后重试，不强制覆盖远端。

**`~/.npm` 里若有 root 属主的文件**，`npx` 会报 `EPERM` 或 `ECOMPROMISED`。把缓存指到可写位置：

```bash
export npm_config_cache=/tmp/npm-cache
```

## 安装版本规则

默认安装与更新都查询 GitHub 最新正式 Release 的 Tag，优先下载该 Tag 的 Release ZIP；如附件缺失，则只回退到**同一个 Tag** 的源码包。显式 `--version x.y.z` 也会检查下载包内的 `SKILL.md` 版本，不会在失败时悄悄安装 `main`。安装开发版请使用 `npx skills add flashfrogluo/second-take`（从仓库安装），而不是把正式版更新命令当成开发分支同步。

发布经 GitHub Actions 双平台测试（Ubuntu / macOS）验证。在 `main` 中提交标题为 `release: v1.7.3` 的发版提交后，CI 全部通过才会运行现有 `release.sh`，核验正式附件，并测试版本安装与更新。其他普通提交不会触发发版。

## 发版检查清单

1. 改 `SKILL.md` 的 `metadata.version`（`release.sh` 会核对，不一致直接拒绝）
2. 更新 `CHANGELOG.md`，加 `## [x.y.z]` 段落（`release.sh` 会抓它作为发布说明）
3. 在独立干净 Git 克隆中运行 `scripts/push-to-github.sh`，完成测试、限定公开路径提交、推送代码。
4. `GITHUB_TOKEN="$(gh auth token)" ./scripts/release.sh x.y.z`（先草稿、核验 ZIP、再正式发布；GitHub 会为新版本创建 tag，无需另行手工推同名 tag）。
5. 核验 GitHub Tags、Release 与附件 URL，确认安装器指向正式版本。
6. 若改了 `description`：**重新安装一次**，让索引抓到新元数据

## 公开文件边界

`public-files.txt` 是逐文件公开清单；新增文件须先检查内容再加入。打包、安装、更新和推送只处理清单中的路径，拒绝私有目录、越界路径和文件符号链接。`corpus/`、`cases/`、`DEVLOG.md`、`metrics/`、环境文件、备份与日志不加入发布包。现有目标目录中的其他文件不会被删除。

工程脚本需要 Python 3，skill 的 Markdown 质检流程仍无运行依赖。安装兼容 1.7.1 中尚不存在的三个新增工具文件；其他清单文件缺失仍报错。公开清单是文件边界，不是内容脱敏器，发布前仍须检查内容。推送脚本应在独立 Git 克隆中运行，不能在包含私有开发资料的真源目录直接提交。
