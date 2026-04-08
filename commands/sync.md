Sync current session to Notion Session Log. Argument: $ARGUMENTS

This command writes the current session's work to the Notion Session Log database for cross-station, cross-project visibility.

## Step 1 — Detect context

Determine the current project and station:

```bash
# Project: from git remote or CLAUDE.md
git remote get-url origin 2>/dev/null
# Station: from hostname
hostname
```

Map the project to the Session Log "Project" field:
- `intropa-finance-pl` → "Intropa PL"
- `ria-hr-portal` → "RIA HR Systems"
- `NeoWealth` or `neowealth-website` → "NeoWealth Website"
- `NeoWealth-CMD` → "NeoWealth CMD"
- `Odoo-*` or `odoo-*` → "Odoo"
- `BLBC-Website` → "BLBC"
- Everything else → "Other"

Map the hostname to the "Station" field:
- Contains `PROBOOK` or `probook` → "intropa-probook"
- If user specifies station in $ARGUMENTS, use that instead
- If ambiguous, ask the user which station this is

## Step 2 — Gather session data

Read HANDOFF.md for session summary.

Get commits from this session:
```bash
git log --oneline --since="8 hours ago" --author="$(git config user.name)" 2>/dev/null
```

## Step 3 — Build session entry

Compose the Notion Session Log entry from:
- **Session title**: `{PROJECT_PREFIX}-S{NN}` (e.g., `PL-S01`, `HRP-S53`). Check HANDOFF.md for the session number, or ask user.
- **Station**: from Step 1
- **Project**: from Step 1
- **Date**: today
- **Summary**: from HANDOFF.md "What was done" section, or compose from git log
- **Commits**: from Step 2
- **Decisions**: any decisions noted in HANDOFF.md or during session
- **Blockers**: any blockers noted
- **Next Up**: from HANDOFF.md "Next Up" section
- **Cross-Station**: any cross-station dependencies noted
- **Duration**: ask user or infer from commit timestamps
- **Session Status**: "Complete" (default), "Interrupted" (if user says so), "Active" (if mid-session)

## Step 4 — Write to Notion

Use the Notion MCP `notion-create-pages` tool to create a new page in the Session Log database.

**Session Log Database ID**: `9a376d2eac714d97a7f8a311368e603e`
**Data Source ID**: `e16a6bff-304b-47bf-976b-78a952578b90`

Create the page with all fields from Step 3.

## Step 5 — Confirm

Show the user what was synced:
- Session title and ID
- Notion link
- Summary of what was recorded

If HANDOFF.md was not updated this session, remind the user to update it before the next session.
