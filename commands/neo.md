Resume NeoWealth project. Argument: $ARGUMENTS

## Step 0 — Bootstrap (runs EVERY time)

Check if the repo exists locally:

```bash
ls ~/code/neowealth/neowealth-website/.git 2>/dev/null
```

**If it does NOT exist**, clone and set up:
```bash
mkdir -p ~/code/neowealth
cd ~/code/neowealth
git clone https://github.com/s00ly/NeoWealth.git neowealth-website
cd neowealth-website
```

**If it exists**, just `cd` into it:
```bash
cd ~/code/neowealth/neowealth-website
```

## Step 1 — Load project rules

Read `CLAUDE.md` for project rules and non-negotiable constraints.
Read `HANDOFF.md` for the latest session state and next steps.

## Step 2 — Run /resume-neo

Execute the project-scoped resume command (`.claude/commands/resume-neo.md`) with the same arguments: `$ARGUMENTS`

If no arguments given, default to `status` mode — fetch state from all sources, determine which batch we're on, and report status. Do NOT execute any batch work unless the user explicitly asks.
