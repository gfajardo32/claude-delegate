---
name: delegate
description: Plan in Claude, delegate the typing. Sends routine coding, hard bugs, reviews and images to the agent the user picked for each (Gemini via Antigravity CLI, OpenAI Codex CLI, or a Claude subagent), all on your existing subscriptions with no API keys. Use for any coding task bigger than a few lines, code reviews, or when the user asks for an image, logo or icon.
---

# Delegate: Claude plans, Gemini and Codex write

Goal: spend Claude tokens on thinking, not typing. You (Claude) plan, split the work,
hand the writing to Gemini or Codex through their official CLIs, and verify the result.
Every tool runs on its own vendor's subscription login. Never use or set API keys.

Scripts live next to this file in `scripts/`. Installed as a plugin, that is
`${CLAUDE_PLUGIN_ROOT}/skills/delegate/scripts/`; installed with `install.sh`, it is
`~/.claude/skills/delegate/scripts/`. Use whichever exists. Run them with
`bash <path to script>` from the project root. Below, `scripts/` means that folder.

## 1. Your role: architect and manager
- Read only what the plan needs: `rg`/`grep` and line ranges, not whole files.
- Break the work into small tasks, each with exact file paths, the change, and how to
  check it (a test command or a behavior).
- Do not write large blocks of code yourself. A few-line fix is fine to do directly
  when delegating would cost more than the edit.
- After each delegated task: `git diff --stat`, then `git diff -- <file>` only for the
  files that matter, then run the relevant tests. Do not re-read whole files.
- You own the final answer. If a delegate's change is wrong, send it back with the exact
  problem, or fix the small part yourself.

## 2. Who does what: the user's menu
The user picks an agent and model for each role with `scripts/menu.sh` (saved in
`~/.claude/delegate.conf`). Check it once per session:

    bash scripts/delegate.sh --show

Then check the tools those settings need:

    bash scripts/setup.sh --check

Any `MISSING <tool>` line: tell the user which tool is missing, what it is for, and the
install command printed under it, and ask if you should run it. Run it only after they
say yes. Sign-in (`agy` first run, `codex login`) opens a browser, so the user does that
in their own terminal. Until a tool is installed and signed in, give its roles to a
Claude subagent and say so. A `MANUAL chrome` line is not an error: mention it only if
you need the browser and it is not connected. If the user has no
`~/.claude/delegate.conf` yet, suggest they run `bash scripts/setup.sh` in their own
terminal to pick tools first (it is interactive, so do not run it yourself).

Then send every task through the router, never straight to a vendor script:

    scripts/delegate.sh light  "<instructions>"   # feature code, boilerplate, edits, renames
    scripts/delegate.sh read   "<question>"       # big codebase reads and summaries, no edits
    scripts/delegate.sh heavy  "<instructions>"   # hard bugs, algorithms, tricky refactors
    scripts/delegate.sh review "<what to review>" # read-only second opinion
    scripts/delegate.sh image  "<what, size, style>" <output path>
    scripts/delegate.sh browser                   # prints BROWSER=<choice>

Exit codes:
- **10**: that role is set to Claude. It prints `CLAUDE_SUBAGENT role=<r> model=<m>`.
  Run the same prompt as a subagent (Task tool) with that model. That is still Claude
  Code on the user's own plan, so it is allowed.
- **5**: that role is turned off. Tell the user and ask how they want it handled.
- **3** (any Codex role): Codex is out of usage; the script printed the reset time. Do not
  retry Codex before then. For code, send the task to the other agent or a Claude subagent
  and tell the user. For images, follow section 4.
- **7** (Gemini): agy can't write in this folder because it is outside agy's
  `trustedWorkspaces`. Do not retry and do not edit the user's agy settings yourself.
  Show the user the folder path the script printed and ask them to add it (or a parent)
  to `trustedWorkspaces`. Meanwhile, send the task to the heavy agent or a Claude subagent
  and say so.

**Orchestrator.** Only Claude orchestrates: planning, splitting and verifying stay in
Claude Code, because routing another vendor's model into Claude's seat (or Claude into
a third-party tool) is what breaks the terms. If `Orchestrator` in `--show` is not
`default` and differs from the model you are running as, tell the user once to run
`/model <name>`. You cannot switch your own model.

**Browser.** `claude-chrome`: use Claude in Chrome (`claude --chrome` / the `/chrome`
command) to load and check pages. `playwright`: use the Playwright MCP server if it is
connected, otherwise tell the user it is not set up. `none`: do not open a browser.

**Changing settings.** When the user asks to change a choice ("use Claude Haiku for light
coding"), run `scripts/menu.sh set KEY=VALUE ...` (keys are in `--show`; set the AGENT
key before its MODEL key). The interactive menu needs a real terminal, so do not run
`menu.sh` with no arguments yourself.

## 3. What the vendor scripts do (the router calls these)
- Gemini, `scripts/gemini-task.sh [--read-only]`: runs `agy` in accept-edits mode (plan
  mode for read-only) with a sandbox and a 10 minute timeout, appends "Do NOT run any
  shell commands. Only create and edit files." (in this mode a run that tries a shell
  command can end with nothing written), and retries once on the fallback model. You run
  tests, builds and servers yourself.
- Codex, `scripts/codex-task.sh [--read-only]` and `scripts/codex-review.sh`: `codex exec`
  in a workspace-write or read-only sandbox, with `OPENAI_API_KEY` removed so it bills the
  ChatGPT plan, never the API.

## 4. Images
Logos, icons, app art, mockups, posters, slide graphics, photos.

- Put the size in the description (1024x1024, 512x512 for icons, 1536x1024 for heroes).
- Open the image to check it before using it.
- Exit code 3 means Codex is out of usage. Do NOT draw a replacement and do not install
  packages to fake one. Leave the image path in the code, tell the user the reset time
  the script printed, and rerun the same command after it.

## 5. Writing a delegation prompt
Every prompt includes:
1. The exact files to touch, and files NOT to touch.
2. What to change and why, in numbered steps.
3. Constraints: keep the existing style, no new dependencies unless stated.
4. Done when: the test command that must pass, or the behavior to check.
5. "Reply with a short summary of what you changed. Do not paste whole files."

## 6. Rules for every delegate
- Never commit, push, open PRs or change git config. Only the user decides that.
- Never touch secrets, `.env` files or credentials.

## 7. When a delegate fails
- CLI error or timeout: retry once with a clearer, smaller prompt.
- The chosen agent fails twice: try the other external agent (Gemini or Codex). That
  fails too: do it yourself (code only; images follow section 4).
- Codex "usage limit": do not retry before the reset time it gives.
- Tell the user whenever a task fell back to you, so they know where tokens went.
