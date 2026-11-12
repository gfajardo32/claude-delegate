# delegate: a Claude Code skill for multi-agent coding on subscriptions

Claude plans. Gemini and Codex write. You keep your Claude usage for the thinking.

> **Made to run inside [Claude Code](https://docs.claude.com/en/docs/claude-code).** This is a
> Claude Code skill: Claude Code is always the orchestrator that plans, delegates and verifies.
> It does not work as a standalone tool or inside other agents.

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

These are the defaults. You choose the agent and model for every role (see
[Choose your agents](#choose-your-agents)), and any role can go to a Claude subagent instead,
so you only need the tools you want.

In a test run (a small website plus a generated hero image), Gemini wrote all of the site
code and Claude did about 30% of the work: planning, serving and verifying.

## Requirements
- [Claude Code](https://docs.claude.com/en/docs/claude-code)
- Optional, only if you pick them: Antigravity CLI (Gemini, Google account) and/or
  Codex CLI (ChatGPT plan, Plus or higher for images). Setup installs them for you.
- macOS or Linux (bash)

## Install
```bash
git clone https://github.com/gfajardo32/claude-delegate.git
cd claude-delegate && ./install.sh
```
This copies the skill to `~/.claude/skills/delegate`, then runs setup: it asks which tools
you want, sets the roles to match, and offers to install only those (it asks before running
anything). Sign in once to each tool you installed (`agy`, `codex login`), then start a new
Claude Code session.

To make Claude use it on every coding task without being asked, add this line to
`~/.claude/CLAUDE.md`:
```
For any coding task bigger than a few lines, code reviews, or images, use the delegate skill.
```

## Choose your agents
```bash
bash ~/.claude/skills/delegate/scripts/menu.sh      # interactive menu
bash ~/.claude/skills/delegate/scripts/setup.sh     # re-run the tool questions and installs
```
| Role | Choices |
|---|---|
| Orchestrator | Claude only: `opus`, `sonnet`, `haiku` or your default |
| Light coding | `gemini`, `codex`, `claude` (+ model) |
| Heavy logic | `gemini`, `codex`, `claude` (+ model) |
| Review | `gemini`, `codex`, `claude` (+ model) |
| Images | `codex`, `none` |
| Browser | `claude-chrome`, `playwright`, `none` |

Choices are saved in `~/.claude/delegate.conf`, outside the repo, so reinstalling keeps them.
You can also just tell Claude ("use Haiku for light coding") and it updates the file.

Why only Claude can orchestrate: every tool has to run in its own vendor's official app on
its own login. Putting another vendor's model in Claude Code's seat, or Claude inside another
tool, is what breaks the terms.

## What's inside
```
skills/delegate/
  SKILL.md                 rules Claude follows: roles, prompt format, verification, fallbacks
  scripts/delegate.sh      router: sends each task to the agent you picked for that role
  scripts/menu.sh          pick agents and models per role
  scripts/setup.sh         first-run questions and installs; --check lists missing tools
  scripts/gemini-task.sh   agy in accept-edits mode, sandboxed, 10 min timeout, fallback model
  scripts/codex-task.sh    codex exec, edits limited to the project folder
  scripts/codex-review.sh  codex exec, read-only review
  scripts/codex-image.sh   $imagegen to a path you choose; exit 3 when Codex is out of usage
```

## Environment overrides
Env vars win over the menu settings for a single run.

| Variable | Default |
|---|---|
| `DELEGATE_GEMINI_MODEL` | `gemini-4-hydrogen-medium` |
| `DELEGATE_GEMINI_FALLBACK` | `gemini-3.8-flash-medium` |
| `DELEGATE_CODEX_MODEL` | Codex's own default |
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

## Author
Built by **Guido M. Fajardo Gabrie**.

- GitHub: [@gfajardo32](https://github.com/gfajardo32)
- LinkedIn: [linkedin.com/in/guidofajardo](https://www.linkedin.com/in/guidofajardo)

Issues and pull requests are welcome.

## License
MIT. See [LICENSE](LICENSE).
