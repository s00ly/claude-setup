Run a plugin compliance check against the manifest in s00ly/claude-setup.

Steps:
1. Find the claude-setup repo. Check these locations in order:
   - ~/AppData/Local/Temp/claude-setup (Windows)
   - ~/claude-setup
   - /tmp/claude-setup
   If not found, clone it: `git clone https://github.com/s00ly/claude-setup.git /tmp/claude-setup`

2. Pull latest: `git -C <repo-path> pull`

3. Run the audit: `bash <repo-path>/sync-plugins.sh --check`

4. Report the result. If non-compliant, ask if I should run the full sync.
