# delegate: a Claude Code skill for multi-agent coding on subscriptions

Claude plans. Gemini and Codex write. You keep your Claude usage for the thinking.

`delegate` turns Claude Code into an architect and reviewer that hands the actual typing to
two other coding agents through their official command-line tools:

| Work | Goes to | Runs on |
|---|---|---|
| Planning, task breakdown, review, tests | Claude Code | your Claude plan |
| Routine coding, edits, boilerplate, big codebase reads | Gemini (Antigravity CLI, `agy`) | your Google account |
| Hard bugs, tricky refactors, second-opinion reviews | OpenAI Codex CLI | your ChatGPT plan |
| Images: logos, icons, mockups, photos | Codex `$imagegen` | your ChatGPT plan (Plus or higher) |

No API keys. Each tool signs in with its own vendor's subscription, in its own official app.
Nothing borrows another company's login.

In a test run (a small website plus a generated hero image), Gemini wrote all of the site
code and Claude did about 30% of the work: planning, serving and verifying.

## Requirements
- [Claude Code](https://docs.claude.com/en/docs/claude-code)
- Antigravity CLI: `curl -fsSL https://antigravity.google/cli/install.sh | bash`, then run `agy` once to sign in
- Codex CLI, signed in with ChatGPT (image generation needs Plus or higher)
- macOS or Linux (bash)

## Install
```bash
git clone https://github.com/gfajardo32/claude-delegate.git
cd claude-delegate && ./install.sh
```
This copies the skill to `~/.claude/skills/delegate`. Start a new Claude Code session.

To make Claude use it on every coding task without being asked, add this line to
`~/.claude/CLAUDE.md`:
```
For any coding task bigger than a few lines, code reviews, or images, use the delegate skill.
```

## What's inside
```
skills/delegate/
  SKILL.md                 rules Claude follows: roles, prompt format, verification, fallbacks
  scripts/gemini-task.sh   agy in accept-edits mode, sandboxed, 10 min timeout, fallback model
  scripts/codex-task.sh    codex exec, edits limited to the project folder
  scripts/codex-review.sh  codex exec, read-only review
  scripts/codex-image.sh   $imagegen to a path you choose; exit 3 when Codex is out of usage
```

## Configure
| Variable | Default |
|---|---|
| `DELEGATE_GEMINI_MODEL` | `gemini-4-hydrogen-medium` |
| `DELEGATE_GEMINI_FALLBACK` | `gemini-3.8-flash-medium` |
| `DELEGATE_TIMEOUT` | `600s` |

Run `agy models` to see the models your account has.

## Lessons baked in
- `agy -p` takes the next word as the prompt, so `-p` always goes last.
- In accept-edits mode, an `agy` run that tries a shell command can end with nothing
  written. Every prompt tells Gemini not to run shell commands; Claude runs tests itself.
- `codex exec` only edits files with `-s workspace-write`.
- With `OPENAI_API_KEY` set, Codex bills the API instead of your plan. The scripts unset it.
- When Codex is out of usage, the skill stops and reports the reset time instead of having
  Claude fake an image.
- Delegates never commit or push.

## License
MIT
