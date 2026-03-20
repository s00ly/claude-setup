Resume RIA HR Portal project. Argument: $ARGUMENTS

## Step 0 — Bootstrap (runs EVERY time)

Check if the repo exists locally:

```bash
ls ~/code/fiat/ria-hr-portal/.git 2>/dev/null
```

**If it does NOT exist**, clone and set up:
```bash
mkdir -p ~/code/fiat
cd ~/code/fiat
git clone https://github.com/s00ly/ria-hr-portal.git
cd ria-hr-portal
git checkout develop
```

**If it exists**, just `cd` into it:
```bash
cd ~/code/fiat/ria-hr-portal
```

## Step 1 — Load project rules

Read `CLAUDE.md` for project rules and non-negotiable constraints.
Read `HANDOFF.md` for the latest session state and next steps.

## Step 2 — Run /resume-hr

Execute the project-scoped resume command (`.claude/commands/resume-hr.md`) with the same arguments: `$ARGUMENTS`

If no arguments given, default to `status` mode — fetch state from all sources, determine current phase, and report status. Do NOT execute any phase work unless the user explicitly asks.
