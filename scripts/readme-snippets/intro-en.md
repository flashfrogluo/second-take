## What it solves

**When an AI's answer disappoints, all you can say is "try again" — you can't pinpoint what's wrong.**

Second Take does one thing: **diagnoses what went wrong, and writes it as an instruction you paste back into the same chat** so that AI produces a better version.

| Without it | With it |
|---|---|
| "No, rewrite it" | "Paragraph 3 states the user's guess as fact; delete those two sentences, keep the rest" |
| Rewrites lose good parts, version by version | Only the named spots change; everything else stays |
| Re-explaining your requirements each time | One instruction carrying the full requirement |

**It does not write the answer for you.** Your original chat holds the context, the history, and what you need to keep — the answer should come from there. This tool only makes clear *how to get that side to fix it*.

---

## Try it in 30 seconds (no install)

Copy [`prompts/abc.md`](prompts/abc.md) as the first message of a new chat, then paste in the result you're unhappy with plus the reasoning behind it.

For the full version (11 reference docs, a 43-item self-check rubric, five modes), install:

```bash
npx skills add flashfrogluo/second-take
```

Works with Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, Windsurf, VS Code, Zed, Goose, OpenCode and dozens more agents.

> ⭐ **If this helped, hit Star in the top-right** — it lands in your Stars list so you can find it again; hit **Watch** for updates. It is currently the only signal that tells me someone is using this.


---

