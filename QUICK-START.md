# Workspace Main Quick Start

## Setup (First Time)

### 1. Create GitHub Repository for Workspace Main
```powershell
gh repo create workspace-main --public --description "Central management for GitHub-based Copilot workspaces"
```

### 2. Add Remote and Push
```powershell
cd "D:\COPilot Workspaces\Workspace Main"
git remote add origin https://github.com/dcrozier007/workspace-main.git
git branch -M main
git push -u origin main
```

### 3. Migrate All Workspaces to GitHub (One Time)
```powershell
.\scripts\Migrate-WorkspacesToGitHub.ps1
```

This will:
- Create GitHub repositories for each workspace (naming: `copilot-workspace-name`)
- Initialize Git for non-Git workspaces
- Push initial commits
- Update the workspace registry

## Daily Workflow

### Before Starting Work

**On any computer:**
```powershell
cd "D:\COPilot Workspaces\Workspace Main"

# Check what's out of sync
.\scripts\Compare-WorkspacesWithRemote.ps1

# Pull latest from all workspaces
.\scripts\Pull-LatestFromAllWorkspaces.ps1
```

### During Work

Work as normal in your workspace (SQL Queries, Server Post Build, etc.):
```powershell
# Edit files, make changes
# When done, commit and push
git add .
git commit -m "Describe your changes"
git push origin main
```

### Switching Computers

When you move to another computer:
```powershell
# First thing - pull latest
cd "D:\COPilot Workspaces\Workspace Main"
.\scripts\Pull-LatestFromAllWorkspaces.ps1

# Now all workspaces are current with other computer's work
```

## Key Commands

### Check Sync Status (Detailed)
```powershell
.\scripts\Compare-WorkspacesWithRemote.ps1 -Detailed
```
Shows behind/ahead/up-to-date status for each workspace.

### Pull Latest from All
```powershell
.\scripts\Pull-LatestFromAllWorkspaces.ps1
```
Syncs all workspaces to their latest GitHub versions.

### Migrate Remaining Workspaces
```powershell
.\scripts\Migrate-WorkspacesToGitHub.ps1
```
Run again if you add new workspaces.

### View Workspace Registry
```powershell
$reg = Get-Content config/workspaces-config.json | ConvertFrom-Json
$reg.workspaces | Format-Table -AutoSize
```

### Add New Workspace to Registry
1. Edit `config/workspaces-config.json`
2. Add entry for new workspace
3. Run migration script
4. The workspace gets a GitHub repository

## Troubleshooting

### Pull fails with merge conflicts
```powershell
.\scripts\Pull-LatestFromAllWorkspaces.ps1 -Force
```

### GitHub authentication not working
```powershell
gh auth login
```

### Workspace not syncing
1. Check workspace is in `config/workspaces-config.json`
2. Verify path exists
3. Run `.\scripts\Compare-WorkspacesWithRemote.ps1 -Detailed`
4. Check Git status manually: `cd <workspace>; git status`

### Reset to latest remote version
```powershell
cd "D:\COPilot Workspaces\YourWorkspace"
git fetch origin
git reset --hard origin/main
```

## Architecture Overview

```
Your Computer:
├── D:\COPilot Workspaces\
│   ├── Workspace Main/              ← Run scripts from here
│   │   ├── scripts/
│   │   │   ├── Compare-WorkspacesWithRemote.ps1
│   │   │   ├── Pull-LatestFromAllWorkspaces.ps1
│   │   │   └── Migrate-WorkspacesToGitHub.ps1
│   │   └── config/workspaces-config.json
│   │
│   ├── SQL Queries/                 ← Synced via GitHub
│   ├── Server Post Build/
│   ├── Generate Demo Scripts/
│   └── ...other workspaces...

GitHub (dcrozier007):
├── workspace-main                   ← Workspace Main repository
├── copilot-sql-queries              ← Each workspace has own repo
├── copilot-server-post-build
├── copilot-generate-demo-scripts
└── ...all workspace repositories...
```

## Multi-Computer Sync

**Day 1 - Computer A:**
1. `cd Workspace Main; .\scripts\Pull-LatestFromAllWorkspaces.ps1`
2. Work in SQL Queries workspace
3. `git commit -m "..."` and `git push origin main`

**Day 2 - Computer B:**
1. `cd Workspace Main; .\scripts\Pull-LatestFromAllWorkspaces.ps1`
2. SQL Queries now has Computer A's changes
3. Continue work

**Day 2 - Back to Computer A:**
1. `cd Workspace Main; .\scripts\Pull-LatestFromAllWorkspaces.ps1`
2. Now has Computer B's changes
3. All workspaces stay in sync

## Next Steps

1. ✅ Create GitHub repo for Workspace Main
2. ✅ Push Workspace Main to GitHub
3. ✅ Run `Migrate-WorkspacesToGitHub.ps1`
4. ✅ Verify all workspaces have GitHub remotes
5. ✅ Add pre-work routine: `Pull-LatestFromAllWorkspaces.ps1`
6. 🔄 Daily workflow: Pull → Work → Commit → Push → Switch computers → Pull
