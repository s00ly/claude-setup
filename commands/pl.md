Resume Intropa P&L V03 project. Argument: $ARGUMENTS

## Step 0 — Bootstrap (runs EVERY time)

Check if the repo exists locally. Try known paths in order:

```bash
ls ~/Desktop/Dev/intropa-finance-pl/.git 2>/dev/null || ls ~/code/fiat/intropa-finance-pl/.git 2>/dev/null
```

**If it does NOT exist at either path**, clone and set up:
```bash
mkdir -p ~/code/fiat
cd ~/code/fiat
git clone https://github.com/s00ly/intropa-finance-pl.git
cd intropa-finance-pl
git checkout v03-nextjs
npm install
```

**If it exists**, `cd` into whichever path was found and ensure correct branch:
```bash
cd <found_path>
git checkout v03-nextjs
git pull origin v03-nextjs
```

## Step 1 — Load project rules

Read `.claude/CLAUDE.md` for project rules and non-negotiable constraints.
Read `HANDOFF.md` for the latest session state and next steps.
Read `docs/WEEK1_CHECKLIST.md` for current sprint tasks (if in Week 1).

## Step 2 — Run /resume-pl

Execute the project-scoped resume command (`.claude/commands/resume-pl.md`) with the same arguments: `$ARGUMENTS`

If no arguments given, default to `status` mode — verify environment, fetch state from all sources, determine current task, and report status. Do NOT execute any task work unless the user explicitly asks.
