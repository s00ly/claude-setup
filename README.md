# Claude Code — Project Setup

Global slash commands and plugin management for cross-device development.

## Bootstrap (new device — one command)

```bash
git clone https://github.com/s00ly/claude-setup.git /tmp/claude-setup && bash /tmp/claude-setup/install.sh && bash /tmp/claude-setup/sync-plugins.sh
```

Installs all commands and syncs all plugins. After this, everything works.

## Commands

| Command | What it does |
|---------|-------------|
| `/pl`   | Resume Intropa P&L V03 |
| `/hr`   | Resume RIA HR Portal |
| `/neo`  | Resume NeoWealth |
| `/sync` | Push session to Notion |
| `/check-plugins` | Audit plugin compliance against manifest |

## Plugin Management

Plugins are managed declaratively via `plugins.txt` (single source of truth).

```bash
bash sync-plugins.sh          # full sync (install, remove, verify)
bash sync-plugins.sh --check  # audit only, no changes
```

To add/remove a plugin: edit `plugins.txt`, commit, push. Other devices pull and re-sync.

## How It Works

```
You type /hr
    |
    v
~/.claude/commands/hr.md  <-- installed by this repo (global routing)
    |
    +- Repo missing? -> auto-clone from GitHub
    +- cd into project
    +- Read CLAUDE.md (rules) + HANDOFF.md (state)
    |
    v
.claude/commands/resume-hr.md  <-- lives in the project repo (travels with git)
    |
    +- Git sync (fetch, fast-forward, detect divergence)
    +- Fetch state (HANDOFF.md, Notion, git log, health checks)
    +- Report status
    +- Ask before executing work
```

## File Layout

```
claude-setup/
  commands/          # slash command definitions
    pl.md
    hr.md
    neo.md
    sync.md
    check-plugins.md
  plugins.txt        # declarative plugin manifest
  settings.json      # non-plugin settings (synced across devices)
  install.sh         # install commands to ~/.claude/commands/
  install.ps1        # Windows PowerShell installer
  sync-plugins.sh    # plugin sync (install/remove/verify)
```

## Adding a New Project

1. Create `commands/<name>.md`
2. Push
3. Re-run `install.sh` on each device

## Updating Plugins

1. Edit `plugins.txt` (add/remove lines)
2. Push
3. Other devices: `git pull && bash sync-plugins.sh`
