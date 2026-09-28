# Second Take · English Usage Manual

> Got an AI answer you're not happy with? Just say "second take" — but this time, bring the retake note.

This is the detailed English guide for **Second Take**, a skill that reviews another AI's reasoning and produces a precise instruction you can paste straight back into the original chat.

If you came from the Chinese README, every section there carries a one-line **EN** note. This document is the complete, expanded English version.

---

## What Second Take does

You got a disappointing result from any AI — **DeepSeek, ChatGPT, Doubao, Gemini, Jimeng, Midjourney…** — and the result can be **text, image, video, prompt, code… anything at all**. Send it the requirement or a share link to the conversation. It then does two things: it reads that reasoning (or, for generative models, the prompt), judges what went wrong, and **produces a retake note you can copy straight back into that AI** — paste it at the end of the original conversation and the other AI gives you a better final answer directly.

```bash
npx skills add flashfrogluo/second-take
```

**Why "Second Take":** the word *take* has two meanings — in film it means "one shot" (let's do another take), and it also means "an opinion or interpretation" (my take on this). The name captures both things we do: **offer a second opinion, then let the original AI reshoot once.**

---

## Film-set vocabulary

Treat one AI generation like shooting a film. This method **packages** the whole review pipeline into film terms — dailies, reshoot, pick-up, continuity, retake note, final cut, color grading, packaging. You don't need to memorize AI jargon; just know these film terms and you can name which step you want.

The table below is your **control panel**: the film term on the left, what it actually has the AI optimize and why on the right.

> ⚠️ **One boundary**: these film terms are the **command interface for invoking this tool**, not the content of the task you hand the AI. If your own request is literally "make a film" and mentions "reshoot / color grading", that's just your domain language — it does not trigger any step here. Triggering happens only when you actively use this tool.

| Our step | Film term (name) | What we have the AI optimize | Purpose |
|---|---|---|---|
| Material under review (CoT + answer) | Dailies / 样片 | Hand over the original AI's reasoning chain and final answer for diagnosis | Locate "right or wrong" issues; decide what stays |
| First full rewrite | Reshoot / 重拍 | When the subject doesn't hold, rewrite the entire reasoning chain | Rebuild the correct structure and judgment |
| Targeted fix in later rounds | Pick-up / 补拍 | Subject already holds; change only the named spots | Keep qualified passages; fix precisely, avoid regression |
| Self-consistency check | Continuity / 穿帮 | Check whether each step internally, steps among themselves, and against the conclusion stay self-consistent | Eliminate logic clashes |
| Incomplete coverage | Missing coverage / 漏镜 | Check whether key branches or factors were missed | Close coverage gaps; avoid overgeneralizing |
| Deliverable (optimization instruction) | Retake note / 重拍单 | Output a copy-ready sheet for the original AI to execute | Let the original AI re-shoot per the sheet |
| Verdict after deadlock | Final cut / 定剪 | When versions conflict, make a trade-off call | Lock the cut; stop rewriting |
| Polish after the subject is locked | Color grading / 调色 | All Four Standards met; polish only (text: wording/tone/rhythm/key lines; image & video prompts: visual descriptors & aesthetic direction) | Raise expressive / visual quality; no structural/factual change, no new claims |
| Presentation at delivery | Packaging / 包装 | Output a summary, mind map, and visualizations | Make the result read clearly and land |

---

## Trigger words (how to invoke, and how to name a mode)

> The tool is invoked by two kinds of words: **general triggers** open the flow; **mode triggers** name which step to run (you can also omit them and let the tool decide from context). Film terms are the "command interface", not your task content — see the boundary note above.

### General triggers (open the tool)

| Intent | Trigger words |
|---|---|
| Unhappy result (QA) | the result is wrong / not usable / misses points / wrong length / sounds robotic / too much AI flavor / wrong format / off-topic / logic is flawed / self-contradictory |
| Hand me material to diagnose | check this reasoning / diagnose this CoT / where did this thinking go wrong / here's a share link / my prompt produces a bad image |
| Optimize / rewrite | improve the prompt / have the original AI redo it / spot errors / review / re-examine / rewrite the CoT / QA it with this rubric |
| Generative platforms | JiMeng / Kling / Midjourney image is wrong / not the frame I wanted / prompt retake note |

### Mode triggers (name the step)

| Mode | Signal (when) | Trigger words (film term + natural intent, with evaluated extensions) |
|---|---|---|
| Reshoot | first pass / core invalid / wrong direction | `reshoot` · rewrite from scratch · start over · full rewrite · this version is completely wrong · redo · reroll |
| Pick-up | after round 2 / core holds / change only a few spots | `pick-up` · revise on top of this version · adjust just these few · add a bit · keep this version · tweak · iterate · fix a few spots |
| Final cut | stuck across rounds / versions conflict / need a ruling | `final cut` · help me choose · which one · lock the draft · make the call · decide · merge conflict |
| Color grading | core perfect (four standards pass) / only lacks polish or style | `color grading` · polish · adjust tone · more visual feel · unify style · refine · improve quality · beautify |
| Packaging | overall meets bar / needs structured visualization | `packaging` · make a diagram · visualize · mind map · comparison table · infographic · dashboard · concept map |

> Extensions were added after evaluation: no semantic overlap with existing modes, and they stay on the "command interface vs task content" side of the boundary.

## Deliverables

1. **A copy-ready optimization instruction** (the core deliverable). Paste it at the end of the original conversation; the other AI gives the final answer directly, without returning another "analysis" or "suggestion."
2. **A diagnosis of a dozen-odd lines**, explaining where the original reasoning went wrong and what this version changes.

This skill **does not** write the answer for you. Your context lives in that AI's conversation, so you must get the result there. If you want it to write directly, just say "write it directly."

The optimization instruction is self-contained: the full UP is embedded, so copying the whole block works without any surrounding context. It **does not embed the original CoT** — the guesses and "thinking voice" inside the CoT are exactly the source of the problem; paste them in and the model will replay the same thought process. We give only: UP + a list of valid conclusions (the sound judgments distilled from the CoT) + revision points + an output-structure skeleton (how many sections, what each says, how long, conclusions first, key points bolded) + output requirements (including a ban on the thinking voice).

What to produce is decided by the UP, not guessed: if the UP is a question or asks for content, produce the **final answer**; if the UP's deliverable *is* the reasoning itself (in prompt engineering, the CoT is the product), produce the **revised CoT**. Both templates are in `references/标注范例.md` (Annotation Examples).

Just paste it at the **end of the original conversation** — no new chat needed. The optimization instruction begins with a **targeted-ignore declaration**: it only cuts that one failing stretch of deep thinking and the single answer it directly produced; your earlier instructions, added requirements, expression habits, and ways of thinking all remain in effect.

This method is domain-agnostic. Its review logic has nothing to do with "what the product is" — copy, plans, code, analysis conclusions, and scoring rubrics all apply equally. Every rule in this skill is abstracted to keep only mechanisms that hold across domains; nothing tied to a single domain is written in.

---

## When to use it

- Check whether a model's chain of thought stays faithful to the user's instructions
- Find unsupported citations, forced reasoning, and common-sense errors in the logic
- QA the prompt / reasoning before batch generation
- Turn "finding faults" experience into a reusable process

---

## Supported models and output types

No matter which AI you use — **DeepSeek, ChatGPT, Doubao, Qwen, Gemini, Claude, Jimeng, Kling, Midjourney, Sora, Runway…** — if you're unhappy with its result, Second Take can take it. The output types it covers are unlimited too:

- **Text:** copy, plans, code, analysis reports, scoring rubrics, papers / reports
- **Image:** generated images, posters, storyboards, covers
- **Video:** shorts, ads, storyboard previews, motion assets
- **Other artifacts:** prompts, configs, tables, and any stretch of "finished thinking but not thought through" reasoning

The only criterion: **does that AI expose its reasoning process?**

| Class | Representative AIs | What we review | What you get | Output type |
|---|---|---|---|---|
| **A Full reasoning** | DeepSeek, Qwen (thinking mode), Gemini, Doubao, Claude | That stretch of deep thinking | Optimization instruction (paste back) | Text / Other |
| **B Reasoning summary only** | ChatGPT (thinking summary), some Doubao / Qwen share snapshots | Summary + infer backward from the product (source noted) | Optimization instruction | Text / Other |
| **C No reasoning (generative)** | Jimeng, Kling, Midjourney, Sora, Runway | **The prompt itself** | Prompt retake note (directly pasteable) | Image / Video |

> Class C is a deliberate adaptation: generative models don't show you their reasoning, but **the prompt is the complete instruction they received** — treat it as the CoT and the root cause of a bad image / clip is equally findable (missing elements, internal conflict, adjectives not operationalized, words the platform doesn't recognize). Three rules: don't fabricate platform parameters, keep the seed and reference images, change only the elements that are actually wrong, and don't throw out the whole image.

---

## What to provide per output type (for the most accurate diagnosis)

The more precise your information, the more precise the diagnosis. Provide the following by output type; you can still run with gaps and fill in later:

| Output you're reviewing | Provide if possible (more = better) | Purpose |
|---|---|---|
| **Text / code / plan** | ① Original user instruction (UP) ② That stretch of deep thinking (CoT) ③ The final answer it gave | CoT is the main evidence; UP checks "which requirement was dropped"; the answer confirms "did the error reach the result" |
| **Summary only (ChatGPT, etc.)** | ① UP ② Thinking summary ③ Final product | Main evidence becomes the product; conclusions note "inferred from product" and state "full reasoning not seen, coverage may be low" |
| **Image / video (generative)** | ① The effect you expected (UP) ② The prompt used (params / seed / reference) ③ This version's output | The prompt is the reasoning; seed / reference decide whether we can "change only the broken element" |
| **With reference / target material** | ① Target (the look you expected) ② Reference (take the one dimension it was named for) ③ The AI artifact to fix | Keep the three distinct to avoid the "loop": if you treat the AI artifact as the standard, every fix makes it more like the original error |
| **Any type** | One line "what you're unhappy about" | Helps us finish the judgment first and take fewer detours; if unstated we infer from UP and product |

---

## Privacy

- This skill runs **locally** — no network, no upload of any of your conversations or materials; diagnostic content exists only in this conversation.
- The requirements, conversations, prompts, and outputs you paste are **used only for this diagnosis** — never collected, trained on, or leaked.
- If you voluntarily contribute a sanitized case (see next section), that's your **active** contribution, unrelated to automatic collection.

---

## Contributing: share your cases and corpus

The hard constraints of this skill were honed one real case at a time. **If you're willing to share an "unsatisfying result" together with its original instruction / prompt, you help us sharpen the judgments** — email **flashfrogluo@gmail.com**, or open an issue / PR in the repository.

- **Sanitize before contributing:** remove real names, client names, internal addresses, and confidential data; keep "task type + instruction + that reasoning / prompt + what you were unhappy about."
- Your cases never automatically enter the public knowledge base; only patterns abstracted into "mechanisms" flow back, and specific nouns are stripped — it helps us without leaking your business.
- Usage suggestions, testing feedback, and collaboration ideas are all welcome.

---

## One complete round-trip

```
You  →  Paste a disappointing AI output, or its conversation share link
It   →  ① A dozen-odd-line diagnosis: which rule broke, which class, overall score by the Four Standards
        ② A retake note (code block, fully copyable)
You  →  Paste the retake note at the end of the original AI's conversation
That AI → Gives a better final answer directly
```

The key is **you don't rewrite the question**: all context, history, and expression habits in the original conversation are preserved; only that failing stretch of reasoning is cut.

---

## Installation

### One-line install to any agent (recommended)

```bash
npx skills add flashfrogluo/second-take
```

The skills CLI supports dozens of agents — Claude Code, Codex, Cursor, GitHub Copilot, Windsurf, Gemini CLI, Cline, VS Code, Zed, Goose, OpenCode — and asks you to pick a target at install time.

### Discovery paths per platform (for manual install)

| Agent | Project-level | User-level |
|---|---|---|
| **Claude Code** | `.claude/skills/` | `~/.claude/skills/` |
| **Codex CLI** | `.agents/skills/` (repo root found upward from cwd) | `~/.agents/skills/` |
| **Cursor** | `.agents/skills/`, `.cursor/skills/` (also reads `.claude/skills/`) | Same paths under `~/` |
| **Gemini CLI** | `.agents/skills/` or `.gemini/skills/` (former preferred) | `~/.agents/skills/`, `~/.gemini/skills/` |
| **GitHub Copilot** | `.agents/skills/`, `.github/skills/`, `.claude/skills/` | `~/.agents/skills/`, `~/.copilot/skills/` |
| **OpenCode** | `.agents/skills/`, `.opencode/skills/`, `.claude/skills/` | `~/.agents/skills/`, `~/.claude/skills/` |
| **WorkBuddy** | — | `~/.workbuddy/skills/` |

**One master copy + symlinks** (the standard setup when sharing across agents, to avoid copies drifting apart):

```bash
mkdir -p .agents/skills .claude
cp -R second-take .agents/skills/
ln -s ../.agents/skills .claude/skills     # Claude Code supports directory symlinks
```

User-level is the same: put the real copy in `~/.agents/skills/`, and point `~/.claude/skills` and `~/.workbuddy/skills/second-take` at it. On Windows, symlinks need Developer Mode; if that's a hassle, copy a duplicate and exclude it in `.gitignore`.

### Prompt-only use

Paste the body of `SKILL.md` directly into a chat. The files under `references/` are optional supplements — read `标注范例.md` (Annotation Examples) for full templates, `成稿自检清单.md` (Self-Check List) for the self-check paragraph, `自生成rubric元指令.md` (Self-Generating Rubric Meta-Instruction) for the hybrid mode, and `经验提炼与思维习惯.md` (Experience Distillation & Thinking Habits) for feeding new experience back into this skill.

---

## Compatibility

- Follows the **agentskills.io** open standard: 6 fields total (`name` / `description` / `license` / `compatibility` / `metadata` / `allowed-tools`); this skill uses the first 5, omits `allowed-tools`, and uses no platform-private fields (such as Cursor's `paths` or Codex's `agents/openai.yaml`), so it won't be silently stripped by other runtimes.
- Directory name matches `name` exactly: `second-take`.
- All `references/` links use relative paths, with no machine-specific absolute paths.
- Pure Markdown — no scripts, no network requests, no system dependencies. Install is trust-by-default and won't trigger security-audit warnings.

---

## Usage

Both of the following work:

```
# Provide a link (most common)
Generate an optimization instruction for me: https://chat.deepseek.com/share/xxxxx

# Paste content directly
Check whether this CoT is correct; if not or if it can be improved, generate an optimization instruction for me.
UP (user instruction): ……
CoT (deep thinking): ……
```

After a link, it calls the API to fetch the original instruction, deep thinking, and that version's product, so you don't type them manually. Once fetched, it confirms with you which is the main instruction, which is the added instruction, and which is the product.

Optional inputs include: material description (Caption), target product, reference material, and instructions you add in later rounds (e.g. "no bullet points, output one long block"). Whichever is missing, the check that depends on it is simply marked "none."

Pure text Q&A with only UP and CoT and no product or material also works; the focus then falls on instruction conflict, incomplete coverage, and reasoning defects.

---

## Evaluation standard: the Four Standards for an effective chain of thought

Whether a chain of thought is effective is judged by four standards. **The Four Standards are the evaluation standard; the check items are the symptom list** — the former answers "is it good," the latter answers "where is it broken."

| Standard | Definition | One-line test |
|---|---|---|
| **Logic** | Each thinking step has a logical relation to the others, connected into a complete process | Can the next step be inferred from the previous one? |
| **Completeness** | Considers the problem as fully and carefully as possible, ignoring no relevant factor or impact | Are the important dimensions mentioned in the UP and material all accounted for? |
| **Feasibility** | Every thinking step can actually be carried out | After reading, do you know the specific next action? |
| **Verifiability** | Every thinking step can be validated by real data and facts | Can each conclusion point to "why do you say so"? |

Process: first find the concrete errors via the check items → map them to the Four Standards → give an overall score → write the optimization instruction from that. The revision points must cover all four; fill whichever is missing.

For per-standard judgment methods and the mapping to check items, see `references/思维链四标准.md` (The Four Standards for Chain of Thought).

---

## Symptom list (check items)

The skill automatically scans for three families of problems — you don't need to memorize these terms:

- **Conflicts**: the product, reference material, or user instruction contradicts one another (product / reference / instruction conflict);
- **Incomplete coverage**: important content of the user instruction was dropped or weakened;
- **Reasoning defects**: contradiction, common-sense error, vague wording, forced reasoning, unsupported citation, self-clearance, version regression, and so on.

The full itemized list and per-item judgment methods live in `references/思维链四标准.md`.

---

## Repository layout

```
second-take/
├── SKILL.md                    # Main flow: input, discipline, check items, 28 hard-constraint points, execution steps
├── references/
│   ├── 硬约束详解.md           # Full explanation of the 28 hard constraints, with counter-examples and correct forms
│   ├── 多场景适配.md           # What DeepSeek/ChatGPT/Gemini/generative platforms can each provide, and how to fix
│   ├── 判定细则.md             # Judgment order, attribution rules, exemption list, sub-type boundaries
│   ├── 思维链四标准.md         # Single source of truth for the Four Standards: definition + per-standard judgment + mapping + how to fix + retake-note rules / five modes / two mechanisms / boundaries
│   ├── 标注范例.md             # Copy-ready optimization-instruction templates A/B/C (placeholders, no case; the full annotated example is kept internal)
│   ├── 成稿自检清单.md         # Self-check paragraph for the target AI: writing rules and item templates
│   ├── 自生成rubric元指令.md   # Hybrid mode: meta-instruction letting the target AI write its own domain standard
│   ├── 优化指令自查rubric.md   # Our pre-delivery five-field self-check (Must-have 18 items)
│   ├── 经验提炼与思维习惯.md   # How cases are abstracted into rules, anti-pollution discipline, fixed mental actions
│   ├── 画面描述规范.md         # Caption writing principles and eight judgments (sanitized from a general spec)
│   └── 术语表.md               # Evaluation-side terms: Rubric's five fields, four hard-injury types, reward hacking
├── docs/
│   ├── 四标准质检法.md         # Entry pointer: merged into references/思维链四标准.md; write no content here
│   ├── 迭代工作流.md           # Maintainer guide: change hard constraints / add reference / add corpus / release checklist
│   ├── guide-en.md             # This file — the full English usage manual
│   └── ROADMAP.md              # Roadmap: done / in progress / envisioned
├── README.md
├── LICENSE
└── .gitignore
```

---

## Five modes: from "is it right" to "does it read clearly"

Not every round needs a full redo. Judge whether the subject holds first, then pick a mode:

| Mode | Film term | When to use | Approach |
|---|---|---|---|
| **Reshoot** | 重拍 | First round, or the previous version's subject doesn't hold (wrong structure, wrong target judgment, large missing items) | Full rewrite |
| **Pick-up** | 补拍 | Later iteration rounds, where the previous version's subject already holds | Change only the named spots; keep the rest as-is |
| **Final cut** | 定剪 | Many rounds in and still producing new errors, or two versions' conclusions contradict each other | Stop rewriting; make a trade-off verdict |
| **Color grading** | 调色 | The subject is already perfect (all Four Standards met, no check-item issues); only the feel / style falls short | Touch structure and facts not at all; only light polish and style strengthening — text: sharpen wording, unify tone, heighten rhythm and visual sense, spotlight key lines; image & video prompts: tighten style / lighting / mood descriptors and strengthen aesthetic direction, but keep the subject unchanged and add or remove no elements |
| **Packaging** | 包装 | The whole thing already meets the output standard, but needs structured presentation so others get it at a glance | Do visualization analysis: output summary, mind map, and visual charts (flow / comparison / relation / timeline) |

Move along the production line: **Reshoot → Pick-up → Final cut → Color grading → Packaging**. The first three answer "is it right"; Color grading answers "is it good enough"; Packaging answers "does it read clearly." **Neither Color grading nor Packaging re-judges the conclusion**: Color grading only polishes expression or visual presentation — no new points, no factual or structural change (for image & video prompts it tunes visual descriptors only, never swapping the subject or adding/removing elements); Packaging only presents the existing conclusion — faithful to the original judgment, never distorting relations for looks. Both assume the subject already passes; if the Four Standards aren't all met yet, do the first three first — don't jump to Color grading or Packaging.

Default to Reshoot; **after the second round, default to Pick-up** — the biggest risk of a rewrite is throwing away qualified content from the previous version (version regression).

---

## The three segments at the end of the optimization instruction (hybrid mode)

The optimization instruction doesn't end after the requirements; three segments follow, in fixed order:

| Segment | Written by | Purpose |
|---|---|---|
| **[Judging Criteria]** | The target AI, per our spec | Define "what good means in this domain" up front, to catch errors we haven't seen |
| **[Known Defects]** | Us (seed entries) | Anchor the actual mistakes the previous version made — it doesn't know which line it deleted |
| **[Self-Check]** | Us (10–12 Yes/No items) | A unified pass after writing; answer "no" and fix on the spot; the self-check process doesn't enter the body |

Why not just write it all ourselves: our items are **after-the-fact** (written after seeing the bad product), so they only guard against seen errors; its self-written items are **before-the-fact** (define the standard right after receiving the UP), guarding against unseen errors. **The two cover different error sets.**

Why not hand it all to it: it will inflate its self-score, and will **infer the standard backward from the previous bad product** (treating "last version had six sections" as the standard), writing unjudgeable items like "is the content reasonable." So the meta-instruction must have guardrails — **every item must state "on what basis," and missing basis counts as "no"**; **standards may come only from the UP and common sense, never from the look of any previous answer**; bare adjectives are forbidden.

Enabled by default. Four cases fall back to giving only **[Self-Check]**: the target model is clearly weak / the UP is minimal / defects are fully enumerable / the user needs the shortest instruction.

---

## Pitfalls we've hit (all now in the hard constraints)

| Lesson | Symptom |
|---|---|
| Embedding full CoT | Output becomes a "hmm, the user is asking…" thinking process instead of an answer |
| Skeleton says only "can be sectioned" | Output is flat text with no hierarchy and no emphasis |
| Meta-requirements enter the body | Body shows "the working definition of this answer," "the judging standard is…"; reader can't tell who's being addressed |
| Fabricating numbers for "verifiability" | Invented precise polling intervals, acceptance-role names — obviously fake, collapsing the whole piece's credibility |
| Mechanical quantitative metrics | "at least two bold spots per section" → everything bold; fixed column count → fields merged pairwise |
| Lists not from one source | Revision points list seven classes, output structure lists six → model follows structure, the seventh vanishes entirely |
| **No placeholder in structure** | Requirements written only in revision points (e.g. the closing question paragraph) are never produced |
| Rewriting from scratch on iteration | Throws away qualified content the previous version already had (version regression) |
| Ignoring the whole conversation | Blanket "ignore all previous answers" also drops habits the user emphasized repeatedly |
| **Saving characters by dropping sentence parts** | "也知道" written as "也知," judgment written as "…rather than…"; reader must supply words to parse |
| Every sentence in the argument starts with "I" | Subject jumps around; objective argument degrades into subjective feeling, reads chaotically |
| Skeleton written as a bullet list | Model copies the skeleton verbatim into an outline; product becomes predicate-less phrase piles |

---

## How experience is distilled into the skill: abstract, don't carry over

Each use yields one more lesson, but **conversation cases are test material, not knowledge**. The distillation order is fixed: **symptom → root cause → mechanism → rule**. Skipping abstraction and writing cases straight into the corpus is using the test set as the training set; the rules will carry that domain's shape and get awkwardly forced onto other domains.

The only judgment standard is the **cross-domain test**: swap every domain-specific noun in the rule for a placeholder and read it again.

- **Still holds** → mechanism, write into the skill;
- **Doesn't hold** → practice, keep in the case file.

One line: **delete the nouns and what remains is what's transferable.**

| Finding in a case | After abstraction (into the skill) | Stays in the case file |
|---|---|---|
| After iterative rewrite, a class of items vanished entirely | Rewrite throws away the previous version's qualified content | What that specific item was |
| A sample table's fields merged pairwise | When column limit conflicts with field count, the model merges fields rather than adding columns | Which fields that table had |
| Sacrificing content to hit a volume metric | Quantifiable metrics get "performed" as assessment items | What that specific number was |

---

## How it differs from similar skills

The community already has many "make AI better" skills, but we're not doing the same thing:

| Category | Representative | What they do | What we do |
|---|---|---|---|
| Generation side: make AI think more | `adhd` (tree-of-thought + pruning), `Reasoning-Skill-Claude`, `auto-reasoning` | Help AI think wider and deeper **at generation time** | Review the stretch it already finished thinking **after generation** |
| Self-reflection side | `self-refine-skill` (GENERATE→CRITIQUE→REFINE→CHECK), `claude-sanity-check` | Have AI **fix its own** current output | Third-party review of **another AI's** reasoning, with a product you can paste back |
| Style side | `avoid-ai-writing` (21 AI-writing patterns), `humanizer` | Remove AI smell, tweak wording | Judge where the reasoning is wrong (missing items, contradiction, unsupported citation, constraint conflict); style is only one dimension |
| Prompt side | `prompt-architect`, `prompt-engineering-expert` | Improve **the prompt itself** | Improve the instruction to "re-answer with the original UP," while preserving the original conversation context |

One line: **what others do is make AI think one more layer, or fix its own style; Second Take does third-party QA — read another AI's already-finished reasoning, judge where it's wrong, and produce a retake note you can paste back so the original AI gives a better final answer.**

---

## FAQ

**Will it write the answer directly?**
No. By default it only gives the retake note. Your context lives in that AI's conversation, so you must get the result there. If you want it to write directly, just say "write it directly."

**Why isn't the original thinking in the retake note?**
Because the CoT itself is the root cause. Once pasted in, the target model replays the same thought process and the output becomes "hmm, the user is asking…". We give only the full UP + the **list of valid conclusions** distilled from the CoT.

**Will pasting back into the original conversation pollute the context?**
The retake note carries a **targeted-ignore declaration**: it ignores only that previous round's stretch of deep thinking and the single answer it directly produced; your earlier instructions, added requirements, and expression habits all stay in effect.

**Does it work on code?**
Yes. Its review logic has nothing to do with "what the product is" — copy, plans, code, analysis conclusions, and scoring rubrics all apply equally.

**What if it's still erroring in the third iteration?**
Switch to Final cut mode: stop rewriting, make a trade-off verdict. If many rounds in still produce new errors, the problem isn't "not rewritten well enough" but the trade-off itself.

**The content is all correct, but it just feels off — can you polish it?**
Yes — that's exactly **Color grading** mode. Once the subject is perfect and all Four Standards pass, it stops touching structure and facts and only does light polish and style strengthening. Text: sharpen wording, unify tone, heighten rhythm and visual sense, spotlight key lines. Image & video prompts: tighten style / lighting / mood descriptors and strengthen aesthetic direction, but keep the subject unchanged and add or remove no elements. It polishes expression or visual presentation only — no new points, no factual or structural change.

**It meets the standard, but I need to present or send it to others — can you give me a glance-readable version?**
Yes — that's exactly **Packaging** mode. Once the whole thing meets the output standard, it does visualization analysis: a one-page summary, a mind map, and visual charts (flow / comparison / relation / timeline). It only presents the existing conclusion, faithful to the original judgment, never distorting relations for looks.

**I only have a CoT, no link — can I use it?**
Yes. Just paste the user instruction and the deep thinking together.

---

## About the author

**flashfrogluo** — came up in film creation (cinematography / directing / screenwriting), now pivoting to AI creation, testing, and development, moving back and forth between "film language" and "AI engineering" for the long term.

The direct motive for this skill comes from the intersection of two identities: on one side, making image work made me keenly sensitive to "why this shot is wrong"; on the other, daily use of various AIs kept hitting the same pain point — the quality of a model's "deep thinking / CoT" is unstable, sometimes with logic jumps, sometimes dropping dimensions the user explicitly asked for, sometimes quietly changing the instruction to match the tone; and pasting that thinking back to re-answer often carries the error along. Second Take wants to turn that "shot-by-shot fault-finding" intuition from the first identity into an operable process for the second: do a **third-party QA**, read another already-finished stretch of reasoning, judge where it's wrong, and produce a "retake note" you can paste straight back so the original AI gives a better final answer.

**All exchange is welcome**: usage suggestions, testing feedback, real conversations usable as corpus, and collaboration ideas — open an issue / PR, or email **flashfrogluo@gmail.com**.

Finally, thank you for using this skill. It's maintained by one person, which is genuinely not easy; but we promise to keep iterating with real needs — the problem you hit is likely the next hard constraint to add. Every piece of your feedback lands directly in the next version's improvements.

---

## Terms

| Abbreviation | Meaning |
|---|---|
| UP (User Prompt) | The requirement and constraints the user gave |
| CoT (Chain of Thought) | The reasoning process under review |
| Caption | A text description of the target product or reference material |

---

## License

MIT. See `LICENSE`.
