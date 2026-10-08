# Second Take · 再来一条

🇨🇳 **中文（本页）** ｜ 🇬🇧 [English](README_EN.md)

[![GitHub stars](https://img.shields.io/github/stars/flashfrogluo/second-take?style=flat&logo=github)](https://github.com/flashfrogluo/second-take)
[![License](https://img.shields.io/github/license/flashfrogluo/second-take?style=flat)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.7.1-blue)](CHANGELOG.md)
[![Agent-Skill](https://img.shields.io/badge/Agent--Skill-agentskills.io-111111?logo=openai)](https://agentskills.io)
[![Downloads](https://img.shields.io/github/downloads/flashfrogluo/second-take/total?style=flat&logo=github)](https://github.com/flashfrogluo/second-take/releases)
[![Last commit](https://img.shields.io/github/last-commit/flashfrogluo/second-take?style=flat)](https://github.com/flashfrogluo/second-take/commits/main)
[![CI](https://github.com/flashfrogluo/second-take/actions/workflows/ci.yml/badge.svg)](https://github.com/flashfrogluo/second-take/actions/workflows/ci.yml)

[![Second Take 主视觉：待改善的 AI 成果 → 重拍单 → 更好的 AI 产出](docs/assets/hero.svg)](https://github.com/flashfrogluo/second-take)

## 它解决什么问题

AI 给的答案不满意时，多数人只能反复说“再改改”。说不清哪里不对，改出来往往更差：要么没改到点子上，要么把原本对的地方也一起改了。

Second Take 只做一件事——把那句“不对”拆开，说清楚是哪一步错了、错在什么性质上，然后写成一段可以整段复制、粘回原对话的指令，让那个 AI 重出一版。

它不代写答案。你的习惯、上下文和满意的产物都保留在原 AI 的对话里；它管的只是“怎么让对方改对”。

🌐 **一页看懂**（它怎么运转、产出长什么样）——[中文](https://flashfrogluo.github.io/second-take/) · [English](https://flashfrogluo.github.io/second-take/index-en.html)

若在 DeepSeek 上用，可直接取用 [`prompts/for-deepseek.md`](prompts/for-deepseek.md)——为它的思考模式调过；其他平台用 [`prompts/abc.md`](prompts/abc.md)。英文读者用对应的 `prompts/for-deepseek-en.md` 与 `prompts/abc-en.md`。

---

## 30 秒试一下（不用安装）

把 [`prompts/for-deepseek.md`](prompts/for-deepseek.md) 整段复制，作为新对话的第一条消息发出去，然后把你不满意的结果和它背后的思考过程贴给它。

想要完整版（11 份参考文档 + 43 条自查 rubric + 五种模式）再安装：

```bash
npx skills add flashfrogluo/second-take
```

> **分享给别人时直接给链接**，不要让对方去搜：搜 `second-take` 会撞上同名子串（scrump / thumbnail 之类）与排序劣势，`second take` 带空格又会落到语义检索按安装量排序。直链见下方 GitHub 与 skills.sh 两处。

支持 Claude Code、Codex、Cursor、Gemini CLI、GitHub Copilot、Windsurf、Cline、Zed、Goose、OpenCode 等几十种 agent。

上面没列到的运行时也能用。本 skill 就是一份 Markdown，只要对方读 `SKILL.md` 就行。WorkBuddy 和 DeepSeek Harness 就属于这种：它们不走 skills CLI，而是各自读自己的 skills 目录，路径见下表。

> ⭐ **如果它帮到你了，点一下右上角的 Star** —— 会进入你账号的 Stars 列表，方便随时找回；点 **Watch** 可订阅更新。这是目前唯一能让我知道“有人在用”的信号。

---

## 一次完整的往返

> **EN** — One round-trip: you paste a bad output or share link → we return a diagnosis + retake note → you paste it back → the AI gives a better answer.

```
您  →  贴一段不满意的 AI 输出，或它的对话分享链接
它  →  在内部完成诊断（错在哪条、归哪一类、按四标准给总评），
       然后把结论写成一张重拍单（代码块，整段可复制）交给你
您  →  将重拍单粘贴回原 AI 的对话末尾
该 AI → 直接给出更好的最终答案
```

您不用把问题重写一遍。原始对话里的上下文、历史、表达习惯都还在，被切掉的只有那段不合格的推理。

## 30 秒上手：一段最短演示（示意）

> 可直接复制的重拍单模板见 `references/标注范例.md`；下面是一段示意。

**输入**：用户要一份“给新手的三条摄影构图建议”，某 AI 的深度思考里写了“根据视觉暂留原理，三分法能让画面更顺眼”，并且只给了两条建议。

**它内部先诊断出（节选）**
- **无据引用（跨领域生搬）**：把“视觉暂留”当依据。它是解释动态画面连续感的生理现象，与静态构图的三分法无关；
- **覆盖不全**：原始指令明确要求三条，只给了两条。

**重拍单（整段复制，粘到原对话末尾）**
> 忽略本对话中上一轮那段深度思考及其产物，其余指令继续有效。重写“给新手的三条摄影构图建议”：① 三分法……② 引导线……③ 留白……。禁止使用“视觉暂留”等跨领域无关论据；只输出正文，不输出分析过程。

**结果**：原 AI 直接给出三条带可操作要点的建议，无生搬硬套的论据。

## 交付内容

> **EN** — What you get: **one retake note**, ready to copy and paste back. A short diagnosis accompanies it so you can see what was wrong and what changed — but the note is the deliverable. We do not write the answer for you; you run it in the original chat.

交付物只有一样：**一段可以复制的重拍单**。粘回原对话末尾，对方 AI 会直接给出最终答案，不会再回你一份“分析”或“建议”。

写单子之前会先做一轮诊断（哪一步错了、错在哪一类、按四标准给个总评），但那是我这边的过程，不占你的操作——你只需要复制那段单子。

本 skill **不会**替您把答案写出来。您的上下文在那个 AI 的对话里，必须在那边拿结果。要它直接写，说一句“你直接写”就行。

重拍单是自包含的：你当初给的指令全文嵌在里面，整段复制走也不依赖任何上下文。

它**不嵌入原始那段深度思考**。里面的臆测和“思考腔”正是问题根源，贴进去模型就会照着重演一遍。

它只给四样东西：你当初给的指令、有效结论清单（从那段深度思考里提炼出的成立判断）、修改要点，以及输出结构骨架（分几节、每节写什么、多长，结论放前面、关键处加粗）和输出要求（含禁用思考腔）。

产出什么要按你给的指令判断，别猜：如果那个要求是提问或要一份内容，就产**最终回答**；如果它要的交付物本身就是推理过程（提示词工程里思考过程即产物），就产**改写后的思考过程**。两个模板都在 `references/标注范例.md`。

直接粘在**原始对话末尾**就行，不用开新对话。重拍单开头自带**定向忽略声明**：只切掉那段不合格的深度思考，以及由它直接产出的一版回答；您之前提出的指令、追加要求、表达习惯和思维方式全部继续有效。

这个方法不限领域。它的审查逻辑跟“产物是什么”无关——文案、方案、代码、分析结论、评分标准都同样适用。本 skill 的所有规则都经过抽象，只保留跨领域成立的机理；任何只在单个领域成立的写法都不写进来。

## 把一次 AI 生成当作拍一部电影（术语与操作面板）

> 这套方法把整套质检流程“封装”成了电影制作：你不必记 AI 专业的术语，只要认得下面的影视说法，就能点名要它做哪一步。
> **可以点名的就是下面这张表**。

![Second Take 五模式流程图：输入 → 分类诊断 → 重拍 → 贴回原 AI → 原 AI 执行 → 用户判断，不满意走补拍 / 定剪再回流；满意则输出，可选调色 / 包装](docs/assets/workflow-zh.png)

| 模式 / 交付物 | 什么时候用 | 做法 | 点名时说 |
|---|---|---|
| **重拍 Reshoot** | 首轮，或主体不成立 | 全量重写 | `重拍` · 从头写 · 推倒重来 · 全量重写 · 这版完全不对 · 重写 · 重来 · 另起一版 |
| **补拍 Pick-up** | 第二轮及以后，主体已成立 | 只改点名的几处，其余按原样沿用 | `补拍` · 在这版基础上改 · 只调这几处 · 补充一点 · 沿用这版 · 微调 · 迭代 · 改几处 |
| **定剪 Final cut** | 多轮僵持，或前后版本冲突 | 不再重写，做取舍裁决 | `定剪` · 帮我取舍 · 选哪个 · 定稿 · 裁决一下 · 拍板 · 合并冲突 |
| **调色 Color grading** | 主体已完美（四标准达标、无检查项问题），只差质感 / 风格 | 不动结构与事实，只做轻微润色与风格强化 | `调色` · 再润色 · 调语气 · 更有画面感 · 风格统一 · 打磨 · 提质感 · 美化 |
| **包装 Packaging** | 整体已达输出标准，需结构化呈现、让人一眼看懂 | 做可视化分析：输出总结、思维导图、可视化图表 | `包装` · 做个图 · 可视化 · 思维导图 · 对比表 · 信息图 · 看板 · 脑图 |
| **重拍单** | 上面每一步都产出它——这是**工具交给你的那张单子** | 本质是一段**优化与检查指令**——既给优化要求，又内带可明确判对错的检查项。可整段复制、粘回原对话，对方 AI 照它直接给出更好的最终答案 | `重拍单` · 生成重拍单 · 给我一张能粘回去的指令 |

**前三种解决“对不对”，调色解决“够不够好”，包装解决“讲不讲得清”。**

**要唤起它，不用点名模式，说这些就够了**：

| 你的情况 | 可以直接说 |
|---|---|
| 结果不满意 | 结果不对 / 很难用 / 漏了要点 / 字数不达标 / 输出不像人话 / AI 味太重 / 格式不对 / 答非所问 / 逻辑有问题 / 前后矛盾 |
| 想让它诊断 | 帮我看看这段思考 / 诊断这个推理 / 这段深度思考哪儿错了 / 贴分享链接 / 这是我的提示词出图不对 |
| 想让它改写 | 优化提示语 / 让原 AI 重写一遍 / 挑错 / 复盘 / 复核 / 改写深度思考 / 用这份 rubric 帮我质检 |
| 生成类平台 | 即梦 / 可灵 / Midjourney 出图不对 / 画面不是想要的 / 提示词重拍单 |

调色和包装都不重新评判结论，它们只在主体已经达标之后动表达和呈现。四标准还没全过，就先走前三种。

第二轮之后默认走补拍。重写最大的风险不是写得不好，而是把上一版已经合格的段落一起丢掉。

交付的东西叫**重拍单**（Retake note）。它本质上是一段**优化与检查指令**——既写明要改什么，又内带可明确判对错的检查项。自包含，粘过去就能用，不依赖任何上下文。

最后说一个容易误会的边界：上面这些影视词只在你**主动使用本工具**时才是指令。如果你自己的活儿就是拍电影，文案里本来就写着“重拍”“调色”，那跟本工具无关，不会触发任何环节。

还有一些影视说法只是环节名，出现在诊断报告里，不能拿来点名：

| 影视说法 | 指什么 |
|---|---|
| **Dailies / 样片** | 待审素材：原 AI 的推理链与最终答案 |
| **Continuity / 穿帮** | 自洽性检查——**检查项，不是模式** |
| **Missing coverage / 漏镜** | 覆盖不全——**检查项，不是模式** |

> 这两个是**检查项**——它们用来判断推理坏在哪，不是你可以点名的模式，所以不会出现在触发词里。

## 默认给轻装版

默认给的是**轻装版**。诊断照旧逐条做完，交付只留最需要的部分，最常见的是**定点修复**：上一版主体已经成立，那就沿用合格的部分，只改几处。

需要**完整版**时说一声“重要 / 详细点 / 往深了查”；或问题明显是结构性的（好几处都不对、方向错、已经改过好几轮还不行），工具也会直接给完整版——全量重写、逐条诊断、成稿自检都会带上。

## 安装

```bash
npx skills add flashfrogluo/second-take
```

一条命令装到你的 agent——安装时会让你从目标列表里选。**支持范围以 `skills` CLI 的当前版本为准**（清单随版本变化，安装时会列出你的版本支持哪些）。

> **搜索时写连字符 `second-take`。** skills.sh 的检索分两种：写 `second-take` 走精确匹配；写成带空格的 `second take` 会切到语义检索，返回按安装量排序的热门 skill，本工具排在几十名开外。

**手动装：各平台把 skill 放在哪**

| Agent | 项目级 | 用户级 |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex CLI | `.agents/skills/` | `~/.codex/skills/` |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| Cline · Zed | `.agents/skills/` | `~/.agents/skills/` |
| Gemini CLI | `.agents/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| OpenCode | `.agents/skills/` | `~/.config/opencode/skills/` |
| Goose | `.goose/skills/` | `~/.config/goose/skills/` |
| WorkBuddy | — | `~/.workbuddy/skills/` |
| DeepSeek Harness | `.agents/skills/` | `~/.agents/skills/` |

**多数 agent 都会读 `.agents/skills/`**——手动装时放这一处通常就够了。没列到的 agent，只要它会读 `SKILL.md` 就能用。

**只想当提示词用（不装）**

把 `SKILL.md` 正文贴进对话即可。不想自己剪的，用现成的**精简应急版**：

- [`prompts/for-deepseek.md`](prompts/for-deepseek.md)｜[`-en`](prompts/for-deepseek-en.md) —— 为 DeepSeek（A 类）调好
- [`prompts/abc.md`](prompts/abc.md)｜[`-en`](prompts/abc-en.md) —— 通用版，覆盖 A / B / C 三类

> ⚠️ 四份都是**精简应急版**（14 条高频硬约束子集，完整版为 34 条）。复制能解决「这一次」；装上才能每次都拿到全量质检。

## 适用模型与产物类型

> **EN** — Supported across all major AIs (DeepSeek, ChatGPT, Gemini, Claude, Midjourney, Sora…) and all output types: text, image, video, and other artifacts — a multi-model, multimodal workflow.

不管您用哪一款 AI，只要它产出的结果您不满意，Second Take 都能接。它覆盖多模型、多模态：**DeepSeek、ChatGPT、豆包、通义千问、Gemini、Claude、即梦、可灵、Midjourney、Sora、Runway……**，文本推理与图 / 视频生成都算。覆盖的产物类型也不受限：

- **文字类**：文案、方案、代码、分析报告、评分标准（rubric）、论文 / 报告
- **图像类**：生图、海报、分镜、封面
- **视频类**：短片、广告、分镜预览、动态素材
- **其他产物**：提示词、配置、表格，以及任何一段“想完了但没想好”的推理

唯一的判断标准：**那个 AI 有没有把推理过程露出来**。

| 类 | 代表 AI | 我们审查什么 | 给您什么 | 产物类型 |
|---|---|---|---|---|
| **A 完整推理** | DeepSeek、通义千问（思考模式）、Gemini、豆包、Claude | 那段深度思考 | 重拍单（粘贴回原对话） | 文字 / 其他 |
| **B 仅推理摘要** | ChatGPT（thinking summary）、部分豆包 / 千问分享快照 | 摘要 + 从产物反推（注明来源） | 重拍单 | 文字 / 其他 |
| **C 无推理（生成类）** | 即梦、可灵、Midjourney、Sora、Runway | **提示词本身** | 提示词重拍单（可直接粘贴） | 图像 / 视频 |

> C 类是本 skill 特意做的适配：生成类模型不给你看推理，但**提示词就是它收到的全部指令**——把它当深度思考来审，出图 / 出片不对的根因同样查得到（漏要素、内部冲突、形容词没操作化、用了平台不认的词）。三条规矩：不编造平台参数、保留 seed 与参考图、只改出问题的要素、不推翻整张图。

## 用法

> **EN** — Usage: paste a share link, or paste the user instruction + thinking process directly. Optional inputs: caption, target, reference, follow-up instructions.

以下两种方式均可：

```
# 提供链接（最常见）
帮我生成重拍单：https://chat.deepseek.com/share/xxxxx

# 直接粘贴内容
帮我检查这一段深度思考是否正确，若不正确或尚可优化，请帮我生成重拍单。
用户指令：……
深度思考：……
```

给链接后，它会自动调接口拿原始指令、深度思考和那版产物，不用您手动输入。拿到后会先跟您确认主指令、追加指令、产出物分别是哪条。

可选输入包括：素材描述（Caption）、目标产物、参考素材，以及您在后续轮次追加的指令（比如“不要分点，输出一长条”）。缺哪一项，依赖它的检查项就直接判“无”。

只有用户指令和深度思考、没有产物和素材的纯文本问答场景也适用，这时检查重点落在指令冲突、覆盖不全、推理缺陷三项。

## 不同产物类型，提供哪些信息最准

> **EN** — What to provide for the most accurate diagnosis, by output type (text/code, summary-only, image/video, with reference, or any type).

给的信息越准，诊断就越准。按产物类型提供以下内容；缺了也能先跑、再补：

| 要审的内容 | 尽量提供（越多越准） | 作用 |
|---|---|---|
| **文字 / 代码 / 方案** | ① 你当初给的指令 ② 那段深度思考 ③ 它最终给出的回答 | 深度思考是主证据；原始指令用来核对“漏了哪条要求”；最终回答用来确认“错有没有带进结果” |
| **只有摘要（ChatGPT 等）** | ① 你当初给的指令 ② 思考摘要 ③ 最终产物 | 主证据换成产物，结论注明“由产物反推”，并写明“没见到完整推理，覆盖度可能偏低” |
| **图像 / 视频（生成类）** | ① 你期望的效果 ② 用的提示词（含参数 / seed / 参考图）③ 本版出图 | 提示词即推理；seed / 参考图决定能不能“只改出错的要素” |
| **带参考 / 目标素材** | ① 目标（您期望的样貌）② 参考（取被点名的那一维）③ 待改的 AI 产物 | 三者要分清，防止“怪圈”：如果把 AI 产物当标准，就会越改越像原错 |
| **任意类型** | 一句“哪里不满意” | 帮我们先做完判定、少绕路；没说我们也能从原始指令和产物反推 |

## 评价标准：有效思维链的四条标准

> **EN** — The Four Standards for an effective chain of thought: Logic, Completeness, Feasibility, Verifiability. Standards judge quality; check items list symptoms.

一段思维链是否有效，按四条标准评价。**四条标准是评价标准，检查项是症状清单**——前者回答“它好不好”，后者回答“哪儿坏了”。

| 标准 | 定义 | 一句话判据 |
|---|---|---|
| **逻辑性** | 每个思考步骤之间有逻辑关系，互相连接，形成完整的思考过程 | 后一步能不能从前一步推出来 |
| **全面性** | 尽可能全面、细致地考虑问题，不忽略可能的因素和影响 | 用户指令和素材里提到的重要维度，是不是都想到了 |
| **可行性** | 每个思考步骤都能被实际操作和实施 | 读完知不知道下一步具体做什么 |
| **可验证性** | 每个思考步骤都能通过实际的数据和事实验证其正确性和有效性 | 每条结论能不能指出“凭什么这么说” |

流程：先按检查项找出具体错误 → 归口到四条标准 → 给总评 → 据此写重拍单。修改要点必须覆盖四条，缺哪条补哪条。

逐条的判定方法、与检查项的映射表见 `references/思维链四标准.md`。

## 症状清单（检查项）

> **EN** — Symptom list (check items): the skill scans for three families of problems — conflicts, coverage gaps, reasoning defects. The full itemized list lives in `references/思维链四标准.md`.

本工具会自动扫描三类问题，你不必记下这些术语：

- **冲突**：产物、参考素材、用户指令之间互相打架（产物冲突 / 参考冲突 / 指令冲突）；
- **覆盖不全**：用户指令里的重要内容被漏掉或弱化；
- **推理缺陷**：前后矛盾、常识性错误、表述模糊、强行推理、无据引用、自我放行、版本退步等。

完整条目与逐条判定方法，见 `references/思维链四标准.md`。

## 重拍单末尾的三段（混合模式）

> **EN** — The retake note ends with three fixed segments: [Judging Criteria], [Known Defects], [Self-Check].

重拍单不是写完要求就结束，末尾还有三段，顺序固定。**“混合模式”说的就是这三段**：领域标准由目标 AI 自己写（事前视角），上一版实际犯过的错由我们给种子条目（事后视角），两份合并成一份清单。

| 段 | 撰写方 | 作用 |
|---|---|---|
| **【判定标准】** | 目标 AI 按我们给的规范自行撰写 | 事前先定义“这个领域什么叫好”，防止我们没见过的错 |
| **【已知缺陷】** | 我们（种子条目） | 锚住上一版实际犯过的错——它不知道自己删了哪一条 |
| **【成稿自检】** | 我们（10–12 条 Yes/No） | 写完统一过一遍，答“否”的当场改，自检过程不进正文 |

为什么不全由工具写死：工具给的条目是**事后视角**（看过坏结果才写出来），只能防住见过的错；让目标 AI 自写的部分是**事前视角**（拿到指令先定义标准），能防住没见过的错。**两者覆盖的是不同的错误集合。**

为什么不能全交给它：它会自我评分膨胀，还会**从上一版的坏产物反推标准**（把“上版分六节”当成标准），写出“内容是否合理”这种判不了的条目。所以元指令必须带护栏——**每条都要写明“凭什么判”，没写依据就算“否”**；**标准只能来自你给的指令和常识，不能来自之前任何一版回答的样子**；禁用裸形容词。

默认启用三段。四种情形退回只给【成稿自检】：目标模型能力明显薄弱 / 用户指令极简 / 缺陷已完全可枚举 / 用户所需为最短指令。

> ⚠️ **可退的只有【判定标准】与【已知缺陷】。【成稿自检】在任何模板（A / B / C）与任何情形下都必带**——它防的是“写完不看一遍”，与产物长短无关。

## 实践中踩过的坑（都已写进硬约束）

> **EN** — Hard-won lessons now baked into the hard constraints (e.g. never embed the raw thinking process; never drop qualified content on a rewrite).

| 教训 | 症状 |
|---|---|
| 内嵌深度思考全文 | 输出变成“嗯，用户问的是……”式的思考过程，而不是答案 |
| 骨架只写“可分节” | 产出没有层级、没有重点的平铺文字 |
| 元要求进正文 | 正文出现“本回答的工作定义”“判断标准是…”，读者分不清在跟谁说话 |
| 为“可检验”编数字 | 编出精确的轮询间隔、验收岗位名，一眼假，整篇可信度跟着塌 |
| 机械量化指标 | “每节至少两处加粗”→ 通篇加粗；限定列数 → 字段被两两合并 |
| 清单不同源 | 修改要点列七类、输出结构列六类 → 模型按结构执行，第七类整条消失 |
| **结构里没占位** | 只写于修改要点中的要求（如收尾询问段）根本不会被产出 |
| 迭代时推倒重写 | 把上一版已有的合格内容一起丢掉（版本退步） |
| 忽略整段对话 | 一刀切“忽略此前所有回答”，把用户反复强调的习惯也丢了 |
| **为压字数省句子成分** | “也知道”写成“也知”、判断句写成“……而非……”，读者得自己补字才能读通 |
| 论述里每句都以“我”开头 | 主语反复跳转，客观论述降格成主观感受，读起来错乱 |
| 骨架写成要点清单 | 模型把骨架原样抄成提纲，产物变成没有谓语的短语堆砌 |

## 与同类 skill 的区别

> **EN** — How we differ: third-party QA of another AI's reasoning, producing a note you paste back — not more thinking, not self-editing.

社区里已经有不少“让 AI 做得更好”的 skill，但我们做的不是同一件事：

| 类别 | 代表 | 它们做什么 | 我们做什么 |
|---|---|---|---|
| 生成侧：让 AI 多想 | `adhd`（tree-of-thought + 剪枝）、`Reasoning-Skill-Claude`、`auto-reasoning` | 在**生成时**帮 AI 想得更广、更深 | 在**生成之后**审查它已经想完的那一段 |
| 自我反思侧 | `self-refine-skill`（GENERATE→CRITIQUE→REFINE→CHECK）、`claude-sanity-check` | 让 AI **改它自己**当次的输出 | 第三方审查**另一个 AI** 的推理，且产物要能粘回原对话 |
| 文风侧 | `avoid-ai-writing`（21 类 AI 写作模式）、`humanizer` | 去 AI 味、改措辞 | 判定推理错在哪（漏项、矛盾、无据引用、约束冲突），文风只是其中一维 |
| 提示词侧 | `prompt-architect`、`prompt-engineering-expert` | 改进**提示词本身** | 改进“拿着原始指令重答一遍”的指令，且保留原对话上下文 |

一句话：**别人做的事，是让 AI 多想一层，或者改它自己的文风；Second Take 做的是第三方质检——读另一段 AI 已经想完的推理，判断错在哪，产出一段能粘回原对话、让原 AI 直接给出最终答案的重拍单。**

## 常见问题

**它会不会直接把答案写出来？**
不会，默认只给重拍单。你的上下文在那个 AI 的对话里，结果要在那边拿。要它直接写，说一句「你直接写」就行。

**为什么重拍单里没有原来的那段思考？**
因为那段思考本身就是问题根源。贴进去模型会照着重演一遍，输出变成「嗯，用户问的是……」。

**粘回原对话会不会污染上下文？**
不会。重拍单自带**定向忽略声明**：只忽略上一轮那段深度思考及它直接产出的那版回答，你之前提的指令、追加要求、表达习惯全部继续有效。

**只有一段深度思考、没有链接，能用吗？**
能。把用户指令和那段思考一起贴进来就行。

**迭代到第三轮还在出错怎么办？**
换**定剪**模式：不再重写，做取舍裁决。多轮还在出新错，说明问题不在「写得不够好」而在取舍。

**内容都对、就是差点意思，或要拿去汇报，能处理吗？**
用**调色**（只润色表达与风格，不动结构事实）或**包装**（输出总结、思维导图、图表，便于汇报）。

## 隐私保护

> **EN** — Privacy: nothing is sent to the author and there is no background collection. The only network call is when you paste a share link: your own machine fetches that shared conversation from its platform (DeepSeek only for now).

- 诊断全程发生在你与 AI 的这次对话里。本 skill **不向作者发送任何内容**，也没有任何后台采集。
- 唯一的联网动作，是**你主动贴分享链接**时：由你自己的机器向那个平台（目前只适配 DeepSeek）请求该分享对话的正文，再交给当前 AI 分析。**它不经过作者，也不会被作者留存。**
- 换句话说：你的内容不交给作者，但贴链接时会交给链接所属的平台——这两件事不是一回事，这里说清楚。
- 您贴进来的需求、对话、提示词、出图，**只用于这次诊断**，不会被收集、训练或外传。
- 如果您自愿把脱敏后的案例贡献出来（见下节），那是您**主动**提供的，跟自动采集没关系。

## 共建此项目：欢迎贡献您的案例与语料

> **EN** — Contributing: send us sanitized failure cases (instructions + reasoning/prompt + what went wrong) to help sharpen the rules.

本 skill 的硬约束，是从真实案例里一条条磨出来的。**如果您愿意把遇见的“不满意结果”连同原始指令 / 提示词分享给我们，能帮我们把判定打磨得更准**——请发邮件到 **flashfrogluo@gmail.com**，或在仓库提交 issue / PR。

- 贡献前请**先脱敏**：去掉真实姓名、客户名、内部地址、涉密数据；留“任务类型 + 指令 + 那段推理 / 提示词 + 您哪里不满意”就行。
- 您的案例不会自动进入公开知识库；只有被抽象成“机理”的规律才会回流，具体名词会被删掉——既能帮我们，也不会泄露您的业务。
- 使用建议、测评反馈、合作意向，也都欢迎。

## 关于作者

**flashfrogluo** —— 电影创作出身（摄影 / 导演 / 编剧），现转向 AI 创作、测评与开发。

做这个 skill 的动机来自两个身份交叉：做影像时对「为什么这一镜不对」特别敏感；日常用 AI 时又反复遇到同一个痛点——模型的「深度思考」质量不稳定，逻辑跳步、漏掉明确要求过的维度。

使用建议、测评反馈、能做语料的真实对话、合作想法，都欢迎提 issue / PR，或发邮件到 **flashfrogluo@gmail.com**。

## License

MIT。见 `LICENSE`。

---

---

## English

This README is in Chinese. For the **full English manual**, see [`docs/guide-en.md`](docs/guide-en.md) —
or [`README_EN.md`](README_EN.md) for the English version of this page. Every section above also carries a one-line `EN` note.
