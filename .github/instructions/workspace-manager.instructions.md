---
name: Workspace Manager Instructions
description: Guidance for managing Copilot workspaces with GitHub as source of truth
applyTo: ["**/*.ps1"]
---

# Workspace Management Instructions

You are a workspace management expert for multi-computer GitHub-based synchronization. When working with PowerShell scripts in this workspace, follow these principles:

## Philosophy

**GitHub is the single source of truth.** All workspaces pull from their GitHub repositories. Workspace Main orchestrates:
- Comparing local ↔ remote versions
- Auto-pulling latest before work
- Migrating workspaces to GitHub
- Maintaining central registry

## Best Practices

### Script Structure
- Use descriptive function names (e.g., `Pull-LatestFromAllWorkspaces`, `Compare-WorkspacesWithRemote`)
- Include help documentation with `-HelpMessage` on parameters
- Validate Git repository state before operations
- Provide color-coded output (Green success, Red errors, Yellow warnings)

### Error Handling
- Use try/catch blocks for all Git operations
- Provide clear error messages with remediation steps
- Exit with meaningful exit codes
- Log failures to `logs/` directory
- Handle network/auth failures gracefully

### Git Operations
- Always verify repository state before operations
- Use `git fetch` to check remote status
- Use `git pull` for safe merges, `git reset --hard` only with `-Force` flag
- Maintain `.gitmodules` consistency via Git commands, not direct edits
- Never force-push to main branch

### Registry Management
- Keep `workspaces-config.json` as source of truth
- Update registry after every sync operation
- Record `lastSync` timestamps
- Validate registry structure before saving
- Backup registry before bulk operations

## Automation Patterns

### Comparison (Compare-WorkspacesWithRemote)
1. Load workspace registry
2. For each workspace:
   - Verify path exists
   - Check if Git repository
   - Fetch latest from origin
   - Count commits behind/ahead
   - Display status
3. Summarize and report total commits behind
4. Suggest pull command if behind

### Synchronization (Pull-LatestFromAllWorkspaces)
1. Load workspace registry
2. For each workspace:
   - Skip if path missing or no remote
   - Skip if already up-to-date (unless -Force)
   - Pull latest with `git pull origin <branch>`
   - Update registry with sync timestamp
   - Log success/failure
3. Save updated registry
4. Exit with error code if any failed

### Migration (Migrate-WorkspacesToGitHub)
1. Verify GitHub authentication
2. Load workspace registry
3. For each workspace:
   - Determine repository name from workspace name
   - Check if GitHub repo exists
   - If exists, link local to remote
   - If not, create new GitHub repository
   - Initialize local Git if needed
   - Push initial commit to GitHub
   - Update registry with GitHub metadata
4. Save updated registry
5. Report migration summary

## Code Style

### PowerShell Conventions
- Use PascalCase for function names and parameters
- Use camelCase for internal variables
- Keep lines under 100 characters
- Use `Write-Host` for colored output, `Write-Output` for data
- Use `$Quiet` parameter to suppress output when called from other scripts

### Configuration Files
- Use JSON for all structured data
- Document schema in comments
- Validate on load with error handling
- Never commit secrets or credentials
- Include version and timestamps

### Status Reporting
```powershell
Write-Host "✓ UP-TO-DATE: WorkspaceName" -ForegroundColor Green
Write-Host "⬇ BEHIND: WorkspaceName (5 commits)" -ForegroundColor Red
Write-Host "⬆ AHEAD: WorkspaceName (2 commits)" -ForegroundColor Yellow
Write-Host "⚠ SKIP: WorkspaceName (no remote)" -ForegroundColor Yellow
Write-Host "✗ ERROR: WorkspaceName" -ForegroundColor Red
```

## Common Patterns

### Processing Registry
```powershell
$registry = Get-WorkspaceRegistry
$registry.workspaces | ForEach-Object {
    if ($_.syncEnabled) {
        # Process this workspace
    }
}
Save-WorkspaceRegistry -Registry $registry
```

### Git Status Check
```powershell
$status = Get-RepositoryStatus -RepositoryPath $wsPath
if ($status.behind -gt 0) {
    Pull-LatestFromRemote -RepositoryPath $wsPath
}
```

### Error Recovery
```powershell
try {
    # Git operation
} catch {
    Write-Error "Operation failed: $_"
    $failureCount++
    continue  # Skip to next workspace
}
```

## Multi-Computer Workflow

**Computer A (morning):**
1. Work on SQL Queries workspace
2. `git add`, `git commit`, `git push` to GitHub
3. Close workspace

**Switch to Computer B:**
1. Run `.\scripts\Compare-WorkspacesWithRemote.ps1` (shows SQL Queries is behind)
2. Run `.\scripts\Pull-LatestFromAllWorkspaces.ps1` (pulls latest)
3. Open SQL Queries workspace (now has latest changes)

**Back to Computer A:**
1. Run `Pull-LatestFromAllWorkspaces.ps1` before work (gets Computer B's changes)
2. Work continues with consistent state

## Safety Guidelines

✅ **DO:**
- Validate paths exist before Git operations
- Use `git fetch` to check status without modifying
- Provide summaries after bulk operations
- Test scripts on single workspace first
- Backup registry before major migrations
- Use `-Quiet` parameter for automation contexts

❌ **DON'T:**
- Directly modify `.gitmodules` or registry JSON
- Force-push to main branch
- Skip GitHub authentication verification
- Delete workspaces without confirmation
- Commit secrets or credentials
- Ignore sync failures — investigate and fix

## Repository Naming Convention

GitHub repositories follow the pattern: `copilot-<workspace-name>` where:
- Workspace name converted to lowercase
- Spaces replaced with hyphens
- Special characters removed
- Example: "SQL Queries" → `copilot-sql-queries`
