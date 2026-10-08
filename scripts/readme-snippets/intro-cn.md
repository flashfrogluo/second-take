## 它解决什么问题

AI 给的答案不满意时，多数人只能反复说“再改改”。说不清哪里不对，改出来往往更差：要么没改到点子上，要么把原本对的地方也一起改了。

Second Take 只做一件事——把那句“不对”拆开，说清楚是哪一步错了、错在什么性质上，然后写成一段可以整段复制、粘回原对话的指令，让那个 AI 重出一版。

它不替你把答案写出来。你的上下文、历史、要保留的东西都在原对话里，结果应该在那边拿到；它管的只是“怎么让对方改对”。

📖 **上手手册**（含五种模式的完整走法）：[https://flashfrogluo.github.io/second-take/](https://flashfrogluo.github.io/second-take/)

若在 DeepSeek 上用，可直接取用 [`prompts/for-deepseek.md`](prompts/for-deepseek.md)——为它的思考模式调过；其他平台用 [`prompts/abc.md`](prompts/abc.md)。英文读者用对应的 `prompts/for-deepseek-en.md` 与 `prompts/abc-en.md`。

---

## 30 秒试一下（不用安装）

把 [`prompts/for-deepseek.md`](prompts/for-deepseek.md) 整段复制，作为新对话的第一条消息发出去，然后把你不满意的结果和它背后的思考过程贴给它。

想要完整版（11 份参考文档 + 43 条自查 rubric + 五种模式）再安装：

```bash
npx skills add flashfrogluo/second-take
```

> **搜索时写连字符 `second-take`。** skills.sh 的检索分两种：写 `second-take` 走精确匹配，能直接找到；写成带空格的 `second take` 会切到语义检索，返回的全是按安装量排序的热门 skill，本工具排在几十名开外——**搜不到不是它没收录，是写法的问题**。

支持 Claude Code、Codex、Cursor、Gemini CLI、GitHub Copilot、Windsurf、Cline、Zed、Goose、OpenCode 等几十种 agent。

上面没列到的运行时也能用。本 skill 就是一份 Markdown，只要对方读 `SKILL.md` 就行。WorkBuddy 和 DeepSeek Harness 就属于这种：它们不走 skills CLI，而是各自读自己的 skills 目录，路径见下表。

> ⭐ **如果它帮到你了，点一下右上角的 Star** —— 会进入你账号的 Stars 列表，方便随时找回；点 **Watch** 可订阅更新。这是目前唯一能让我知道“有人在用”的信号。

---

## 流程图：五种模式一条工作流

![Second Take 五模式流程图：输入 → 分类诊断 → 重拍 → 贴回原 AI → 原 AI 执行 → 用户判断，不满意走补拍 / 定剪再回流；满意则输出，可选调色 / 包装](docs/assets/workflow-zh.png)

> 上方是**中文版**；英文版见 [`docs/assets/workflow-en.png`](docs/assets/workflow-en.png)。
> 源文件（SVG / Mermaid）与设计规范在开发工作区，不随本仓库发布。
