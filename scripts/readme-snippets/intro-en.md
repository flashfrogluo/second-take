## What Second Take does

You got a disappointing result from any AI — **DeepSeek, ChatGPT, Doubao, Gemini, Jimeng, Midjourney…** — and the result can be **text, image, video, prompt, code… anything at all**. Send it the requirement or a share link to the conversation. It then does two things: it reads that reasoning (or, for generative models, the prompt), judges what went wrong, and **produces a retake note you can copy straight back into that AI** — paste it at the end of the original conversation and the other AI gives you a better final answer directly.

```bash
npx skills add flashfrogluo/second-take
```

> ⭐ **If this skill is useful to you, please hit Star** — it lands in your Stars list so you can find it again; hit **Watch** to subscribe to releases and discussions.<br>
> Installs are counted via `npx skills add` CLI telemetry (opt out with `DISABLE_TELEMETRY=1`). Each install is recorded once — one install from you is the most direct feedback.

**Why "Second Take":** the word *take* has two meanings — in film it means "one shot" (let's do another take), and it also means "an opinion or interpretation" (my take on this). The name captures both things we do: **offer a second opinion, then let the original AI reshoot once.**

📖 **Handbook** (the full walkthrough of all five modes): [https://flashfrogluo.github.io/second-take/](https://flashfrogluo.github.io/second-take/)

For DeepSeek, use [`prompts/for-deepseek-en.md`](prompts/for-deepseek-en.md) — tuned for its thinking mode; for other platforms use [`prompts/abc-en.md`](prompts/abc-en.md). Chinese readers: `prompts/for-deepseek.md` and `prompts/abc.md`.

---

## Try it in 30 seconds (no install)

Copy [`prompts/for-deepseek-en.md`](prompts/for-deepseek-en.md) in full and send it as the first message of a new chat, then paste the result you are unhappy with together with the thinking process behind it.

Want the full version (11 reference documents + a 43-item self-check rubric + five modes)? Install it:

```bash
npx skills add flashfrogluo/second-take
```

> ⭐ **If it helped, hit Star** — it lands in your Stars list so you can find it again; hit **Watch** to follow updates. Right now that is the only signal telling me someone is using it.

---

## Workflow diagram: five modes, one pipeline

![Second Take five-mode workflow: input → classify & diagnose → reshoot → paste back to the original AI → the original AI runs it → your call; if not satisfied, pick-up / final cut loop back; if satisfied, output, with color grading / packaging optional](docs/assets/workflow-en.png)

> This is the **English version**; the Chinese version is at [`docs/assets/workflow-zh.png`](docs/assets/workflow-zh.png).
> The sources (SVG / Mermaid) and the design spec live in the development workspace and are not published with this repository.
