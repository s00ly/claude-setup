# Claude Code — Project Setup

Global slash commands for cross-device project resumption with Claude Code.

## Quick Start (any new device)

### 1. Install Claude Code

From your Anthropic subscription — follow the official install instructions.

### 2. Bootstrap (paste this into Claude Code)

```
Clone https://github.com/s00ly/claude-setup to ~/code/claude-setup and run the install script.
```

That's it. Claude detects your OS and runs the correct installer.

### 3. Use

| Command | Project |
|---------|---------|
| `/hr`   | RIA HR Portal — biometric attendance + HR management |
| `/neo`  | NeoWealth — Bitcoin education platform |

Each command auto-clones the project repo if it's not on your machine yet.

## Manual Install (if you prefer)

**Linux / macOS / Git Bash:**
```bash
git clone https://github.com/s00ly/claude-setup.git ~/code/claude-setup
~/code/claude-setup/install.sh
```

**Windows PowerShell:**
```powershell
git clone https://github.com/s00ly/claude-setup.git $HOME\code\claude-setup
& "$HOME\code\claude-setup\install.ps1"
```

## Adding a New Project

1. Create `commands/<name>.md` in this repo
2. Push
3. Re-run `install.sh` (Linux) or `install.ps1` (Windows) on each device

## How It Works

```
You type /hr
    │
    ▼
~/.claude/commands/hr.md  ◄── installed by this repo (global routing)
    │
    ├─ Repo missing? → auto-clone from GitHub
    ├─ cd into project
    ├─ Read CLAUDE.md (rules) + HANDOFF.md (state)
    │
    ▼
.claude/commands/resume-hr.md  ◄── lives in the project repo (travels with git)
    │
    ├─ Git sync (fetch, fast-forward, detect divergence)
    ├─ Fetch state (HANDOFF.md, Notion, git log, health checks)
    ├─ Report status
    └─ Ask before executing work
```
