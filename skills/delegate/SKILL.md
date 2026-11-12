---
name: delegate
description: Plan in Claude, delegate the typing. Sends routine coding to Gemini (Antigravity CLI), hard bugs, refactors and reviews to OpenAI Codex CLI, and image generation to Codex, all on your existing subscriptions with no API keys. Use for any coding task bigger than a few lines, code reviews, or when the user asks for an image, logo or icon.
---

# Delegate: Claude plans, Gemini and Codex write

Goal: spend Claude tokens on thinking, not typing. You (Claude) plan, split the work,
hand the writing to Gemini or Codex through their official CLIs, and verify the result.
Every tool runs on its own vendor's subscription login. Never use or set API keys.

Scripts live next to this file in `scripts/` (normally `~/.claude/skills/delegate/scripts/`).
Run them with `bash <path to script>` from the project root.

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

## 2. Routine coding: Gemini (Antigravity CLI, `agy`)
Feature code, boilerplate, file edits, renames, large codebase reads and summaries.

    scripts/gemini-task.sh "<instructions>"            # may edit files
    scripts/gemini-task.sh --read-only "<question>"     # reads and answers only

The script runs `agy` in accept-edits mode with a sandbox and a 10 minute timeout,
appends "Do NOT run any shell commands. Only create and edit files." (in this mode a run
that tries a shell command can end with nothing written), and retries once on a fallback
model. You run tests, builds and servers yourself.

## 3. Hard problems: Codex CLI
Complex algorithms, gnarly bugs, tricky refactors, second opinions.

    scripts/codex-task.sh "<instructions>"     # edits inside the project folder only
    scripts/codex-review.sh "<what to review>"  # read-only review

## 4. Images: Codex image generation
Logos, icons, app art, mockups, posters, slide graphics, photos.

    scripts/codex-image.sh "<what to make, size, style>" <output path, e.g. public/img/hero.png>

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
- Gemini fails twice: send the task to Codex. Codex fails: do it yourself (code only;
  images follow section 4).
- Codex "usage limit": do not retry before the reset time it gives.
- Tell the user whenever a task fell back to you, so they know where tokens went.
