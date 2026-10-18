# 触发测试集（description 覆盖率）

> 用途：检验 `SKILL.md` 的 `description` 是否覆盖了用户真实会说的话。
> 自动部分由 `tests/test_trigger.py` 在 CI 里跑；语义部分需要人工验证（见文末）。

## A. 应触发（正常）

| # | 用户可能会说 | 依据（description 里应出现的线索） |
|---|---|---|
| A1 | 帮我看看这段深度思考对不对 | 深度思考 / chain-of-thought / reasoning |
| A2 | 这个答案很难用，帮我优化一下 | 很难用 / bad / unusable |
| A3 | https://chat.deepseek.com/share/xxxxx | 分享链接 / share link |
| A4 | 生成新的 cot 优化提示语 | CoT / 优化提示 / prompt QA |
| A5 | 让原来的 AI 重写一遍 | 让原 AI 重写 / retake note / paste back |
| A6 | 这个回答漏了好几个要点 | 漏了要点 / missing |
| A7 | 这篇超字数了，帮我压一压 | 字数不达标 / word count |
| A8 | AI 写的东西太像 AI 了，怎么改 | AI 味太重 / 不像人话 / AI-flavored |
| A9 | 帮我检查这份评分标准（rubric）写得对不对 | rubric / 评分标准 |
| A10 | 这段推理是不是想错了 | 推理 / reasoning |

## B. 表达变化后仍应触发

| # | 用户可能会说 | 依据 |
|---|---|---|
| B1 | 只贴一段思维链，什么都不说 | 一段深度思考（输入形态，无需动词） |
| B2 | 帮我改一下这段话，但我要让原来的 AI 自己改 | 不是润色，是让原 AI 重写 |
| B3 | can you check this reasoning? | reasoning / review |
| B4 | 这个视频提示词跑出来不对，帮我改改 | 视频 / 提示词 / prompt |
| B5 | 我要一张能粘回去的指令 | retake note / 可粘回原对话 |

## C. 不应触发

| # | 用户可能会说 | description 里应有的排除 |
|---|---|---|
| C1 | 帮我写一份产品发布会方案 | 从零创作 |
| C2 | 帮我解释一下什么是深度思考 | 纯信息查询（无需诊断已有推理） |
| C3 | 今天天气怎么样 | 纯信息查询 |
| C4 | 陪我聊会儿天 | 闲聊 |
| C5 | 把这段英文翻译成中文 | 从零创作 / 纯转换（无既有推理待诊断） |

## 人工验证方法（语义部分，自动测不了）

1. 新开会话，**不提 skill 名字**，把 A/B/C 每行原样粘进去。
2. 观察：是否自动加载了 second-take。
3. 记录：A/B 未加载 → 补 description 触发词；C 被加载 → 缩窄适用场景或在 description 补排除。
4. 每次改 description 后**全量重跑**，不要只测新补的那条。

## 与问题定位表的对应

| 现象 | 先改哪里 |
|---|---|
| 没有触发 | `description` |
| 经常误触发 | 缩窄适用场景（补排除项） |
| 触发了但流程错 | `SKILL.md` 工作流 |
| 质量不稳定 | 示例 / 模板 / Rubric |
| 信息过时 | `references/` 或动态数据来源 |
| 太臃肿 | 拆成多个聚焦 skill |
