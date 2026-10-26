# 开发者更新日志 · second-take

面向维护者。记录**公开 CHANGELOG 里不写**的东西：改动的动机、排查过程、踩过的坑、以及"下次别这么干"。

分工（见 `docs/迭代工作流.md` 铁律 3）：
- **`CHANGELOG.md`（公开）**：只写用户能感知的变化。
- **`DEVLOG.md`（本文件，不发布）**：写为什么这么改、错在哪、怎么发现的。

---

## 2026-10-09 · 1.7.1 收尾

### Pages 一直不更新：中文文件名让 Jekyll 构建失败

线上 `flashfrogluo.github.io/second-take/` 长期停在旧版（4,201 字节，10-07 的产物），内容全推上去了但页面不更新。

排查：`GET /repos/.../pages` → `status: errored`、`build_type: legacy`；`/pages/builds` 显示连续 `Page build failed.`。
根因：`docs/` 下的中文文件名（`使用与迭代.md`、`四标准质检法.md`、`迭代工作流.md`）让 legacy Jekyll 管线构建失败。

处置：加 `docs/.nojekyll`（纯静态站点本就不需要 Jekyll）。加完立即 `built`。
**教训**：Pages 走 legacy Jekyll 时，`docs/` 里放非 ASCII 文件名是雷。

### 表格退化成原始文本：分隔行列数与表头不匹配

读者反馈「乱码了很难看」。实际是 Markdown 表格的分隔行只有 3 列、表头 4 列。

来源：早先版本该表确为 3 列；我把「别名」从第 1 列挪进第 3 列时**改了表头、漏改分隔行**。严格渲染器因此拒绝渲染整张表，把 `| … |---|---|---|` 原样输出。

**教训**：改表格结构后要跑一次列数校验（全仓扫一遍，当时只此 1 处）。

### Pages 路径与 OG 图片的引用方式

`docs/index-en.html` 里 OG 图片最初写成根目录的 `social-card-zh.png`，与中文页不一致。
改为统一用 `assets/social-card-en.png`。（后于根目录整理时删除了根目录那两份冗余副本——引用全在 `assets/`，两份内容逐字节相同。）

### 主视觉图片：`<picture>` 不认页面手动主题

`<picture>` 的 `media="(prefers-color-scheme: light)"` **只认系统偏好**，不认页面自己的 `data-theme`。
现象：系统浅色 + 手动切深色时，图片不换。

处置：改为双 `<img>` + CSS 按 `data-theme` 切换，规则写成「手动优先于系统」：
```css
.hero .hero-light{display:none}
@media (prefers-color-scheme: light){
  :root:not([data-theme="dark"]) .hero .hero-dark{display:none}
  :root:not([data-theme="dark"]) .hero .hero-light{display:block}
}
:root[data-theme="light"] .hero .hero-dark{display:none}
:root[data-theme="light"] .hero .hero-light{display:block}
```
代价：两张 SVG 都会下载（各约 9KB）。可接受。

### 流程图色带被拉伸：`grid-auto-rows:1fr` 的副作用

为让五格等高加了 `grid-auto-rows:1fr`。但回流线 `.loop{grid-column:1/-1}` 也是网格项，被撑成一整行高（119px，实际只需 30px），下方链接因此离了 103px。

处置：去掉 `grid-auto-rows:1fr`（单行布局里本就不需要，五格内容同高自然等高）；`.loop` 加 `align-self:start`。

### 760px 断点的流程图本来就是坏的

3 列网格 × 9 个子项 + 回流线挤在一起：③ 被压成 103px 窄条、回流虚线横穿卡片、⑤ 挤出视口。
处置：≤760px 直接竖排，与手机同一套逻辑。

### 发布包排除 `cases/`

`cases/重拍单自身缺陷.md` 是对自身指令的敌意审查记录，属内部语料。
`.gitignore` 与 `scripts/release.sh` 的 EXCLUDES 都没排除它 —— 会随包发给用户。已补两处。

### 误删 CHANGELOG 历史

重写 1.7.0 条目时，覆盖了 `## [1.6.1]` 之前的**全部历史**（1.6.0 → 1.0.0–1.0.9）。
从 `.sync-backup-20261006-003351/CHANGELOG.md` 逐字恢复。
**教训**：改动任何文件前先跑 `~/.dsh/backups/second-take/snapshot.sh <文件> <标签>`。

---

## 2026-10-08 · 1.7.1

### GitHub 搜索为什么搜不到

- `second-take in:name` → 第 1（★1 即可压过 6 个 ★0 同名仓库）
- `second-take`（裸搜）→ 第 13~15，2,276 个结果。GitHub 把 `second-take` 拆成 `second` + `take` 两个普通词，命中「Take a screenshot」「Takes a function」这类无关仓库；进首屏门槛约 ★160。
- `重拍单`（不带引号）→ 40 个结果、第 5，但**全是假命中**（「重**命名** / **拍**摄 / **单**张」凑字）。加引号 `"重拍单"` → **1 个结果，就是我们**。
- 结论：**没有别人在用这个词**。曾据结果数（40）推断"有人在用"，是错的 —— 先看内容再下结论。

### 检索锚点的取舍

- 仓库 `description` 从 148 → 279 字符，补 `retake note` / `AI reasoning QA` / `deep thinking`。
- topics：GitHub **上限 20 个**，19+3=22 被拒（422）。去掉信息量最低的 `skill`（已被 `agent-skills` 覆盖）与 `workflow`，换入 `retake-note` / `prompt-qa` / `ai-reasoning`。
- `SKILL.md` 的 `description`（skills.sh 索引的就是它）补 `retake note` / `reasoning` / `deep thinking`，556 → 610 字符。

### 流量数据不可信的部分

`traffic/clones` 2,024（唯一 713）是 `traffic/views` 294（唯一 42）的 **6.9 倍** —— 异常。
来源：CI 拉取、我反复用 API 取文件、爬虫。**真实盘子看 views 唯一数。**
另：`traffic/popular/paths` 把 README 和 Pages 都归到 `/flashfrogluo/second-take`，`referrers` 才分得开。

### Python 的 SSL 证书问题伪装成「文件不存在」

推送脚本初版用 `urllib`，全部抛 `CERTIFICATE_VERIFY_FAILED`；我的 `except` 返回 `None`，脚本把它当成「远端无此文件」，于是报出「57 个文件全需新建」。
**教训**：不要在异常处理里把错误吞成业务语义。改用 `curl` 后正常。

---

## 2026-10-07 · 1.7.0

### 硬约束条数必须三处一致

`SKILL.md` 正文、`references/硬约束详解.md`、README 目录树三处的条数要对齐（当前 34）。改一条要同步三处，容易漏。

### 平台表不能凭空写

原表里的 VS Code 并不在 `skills` CLI 的 agent 定义中（全文搜索 0 命中），已删。
agent 数不写死 —— CLI 定义随版本变（当时 58，现 79）。
另补「本 skill 本体只是一份 Markdown，任何能读 `SKILL.md` 的运行时都能用」：**『CLI 支持』与『本 skill 可用』是两件事**。

### 中文 README 去缩写，英文保留

当时把两个缩写视为中文语境的负担（26 处），改成自然表述；英文语境因常见且术语表已定义而保留。

---

## 2026-10-27 · 外部评审：awesome-copilot PR 被拒

PR #5172（github/awesome-copilot，★40k）由维护者 aaronpowell 于 10-22 关闭，三条理由：

1. **范围不符** —— 该库面向编码 agent，second-take 批评任意聊天机器人的回答（含图像/视频提示词）。
2. **抓取未公开接口 + 伪造 User-Agent** —— 指 SKILL.md 里那段 `-A "Mozilla/5.0 … Chrome/120 …"`。
3. **纯中文内容** —— 维护者难以审阅与跟进。

对方给了一条路：「英文版、聚焦『编码 agent 改代码前审查计划』，欢迎作为新 PR」。

### 已处置：UA 伪装

实测四种请求（share_id=kadwpaqey00sx4ri33）：

| UA | 结果 |
|---|---|
| Chrome 完整 UA + Referer | 200，124 条消息 |
| `second-take/1.7.3 (+https://…)`（自报身份） | **200，124 条消息** |
| `Mozilla/5.0`（裸） | 200 |
| `curl/8.7.1`（默认） | **429** |
| 无 Referer（用可用 UA） | 200 |

**结论**：端点只拒绝 `curl/*` 这类默认 UA，**自报身份完全够用**，Referer 也非必需。
已把 SKILL.md 的写法改为自报 UA，并附一段说明：这是只读 GET、不携带凭证、取的是分享者已公开的内容。
**教训**：为了"能拿到数据"而冒充浏览器，在安全审阅者眼里就是规避检测——**能自报身份就自报**。

### 未处置

- 英文版：SKILL.md 主体仍是中文，这是进国际榜单的硬门槛（多条渠道都提过）。
- 代码场景版本：是否要做，未决。
