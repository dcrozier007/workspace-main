# Workspace Main

Central management hub for all Copilot workspaces. This workspace:
- Synchronizes agent and instruction configurations across all workspaces
- Automates GitHub repository creation and updates for each workspace
- Provides scripts and templates to bootstrap new workspaces
- Maintains workspace structure and best practices

## Quick Start

```powershell
# Initialize all workspaces with Copilot customizations
.\scripts\Initialize-AllWorkspaces.ps1

# Sync latest customizations to all workspaces
.\scripts\Sync-AllWorkspaces.ps1

# Create and push a new workspace to GitHub
.\scripts\Create-NewWorkspace.ps1 -WorkspaceName "My New Project" -Description "Project description"

# Update a specific workspace's GitHub repository
.\scripts\Update-WorkspaceRepository.ps1 -WorkspacePath "D:\COPilot Workspaces\My Workspace"
```

## Directory Structure

```
Workspace Main/
├── .github/
│   ├── agents/                  # Shared Copilot agents
│   ├── instructions/            # Shared instructions by file type
│   └── workflows/               # GitHub Actions (optional)
├── scripts/
│   ├── Initialize-AllWorkspaces.ps1
│   ├── Sync-AllWorkspaces.ps1
│   ├── Create-NewWorkspace.ps1
│   ├── Update-WorkspaceRepository.ps1
│   └── utilities/
│       ├── GitHub-Utils.ps1
│       └── Workspace-Utils.ps1
├── templates/
│   ├── workspace-template/      # Template for new workspaces
│   ├── copilot-instructions.template.md
│   ├── .workspace-config.template.json
│   └── README.md
├── docs/
│   ├── WORKSPACE-CREATION.md
│   ├── GITHUB-SETUP.md
│   ├── AUTOMATION-GUIDE.md
│   └── TROUBLESHOOTING.md
└── config/
    └── workspaces-config.json   # Central workspace registry
```

## Key Features

### 1. Centralized Configuration Management
- All agent definitions in `.github/agents/`
- All instruction files in `.github/instructions/`
- Single source of truth for Copilot customizations

### 2. Automated Workspace Initialization
- Create new workspace from template
- Inject customizations via `.github/` submodule
- Configure `.copilot-instructions.md`
- Initialize with appropriate folder structure

### 3. GitHub Repository Automation
- Create GitHub repository from CLI
- Configure remotes and branches
- Push initial commit with proper structure
- Update existing workspaces' remote URLs

### 4. Workspace Synchronization
- Pull latest from Workspace Main
- Update all submodules
- Verify agent/instruction integrity
- Report sync status and conflicts

## Workflow

### Setting Up a New Workspace

```powershell
# 1. Create workspace from template
.\scripts\Create-NewWorkspace.ps1 `
  -WorkspaceName "SQL Performance Tuning" `
  -Description "Advanced SQL Server performance optimization workspace"

# 2. Workspace is automatically:
#    - Created from template
#    - Initialized with Git
#    - Connected to Workspace Main customizations
#    - Ready for GitHub push

# 3. Open in VS Code and start working
code "D:\COPilot Workspaces\SQL Performance Tuning"
```

### Updating All Workspaces

```powershell
# 1. Make changes to agents/instructions in this workspace
# 2. Commit changes locally
git add .github/
git commit -m "Add new SQL Server tuning agent"

# 3. Sync all workspaces to get latest
.\scripts\Sync-AllWorkspaces.ps1

# 4. Each workspace pulls latest customizations from Workspace Main
```

### Publishing Workspace Changes to GitHub

```powershell
# Update specific workspace's GitHub repository
.\scripts\Update-WorkspaceRepository.ps1 `
  -WorkspacePath "D:\COPilot Workspaces\SQL Performance Tuning" `
  -Commit "Add performance monitoring scripts"

# Or update all workspaces to GitHub
.\scripts\Update-AllWorkspacesRepository.ps1
```

## Workspace Registry

Central registry of all managed workspaces maintained in `config/workspaces-config.json`:

```json
{
  "workspaces": [
    {
      "name": "SQL Queries",
      "path": "D:\\COPilot Workspaces\\SQL Queries",
      "description": "SQL query development and optimization",
      "github": {
        "owner": "dcrozier007",
        "repo": "copilot-sql-queries",
        "url": "https://github.com/dcrozier007/copilot-sql-queries"
      },
      "syncEnabled": true,
      "lastSync": "2026-11-22T16:48:00Z"
    }
  ]
}
```

## GitHub Organization Setup

Workspaces push to repositories under your GitHub account (`dcrozier007`). Each workspace:
- Has its own repository (e.g., `copilot-sql-queries`)
- Includes `.github/` as a submodule pointing to Workspace Main
- Automatically syncs latest customizations via submodule updates

## Common Tasks

### Add a New Agent
1. Create `.github/agents/my-agent.agent.md` in Workspace Main
2. Create `.github/instructions/my-agent.instructions.md`
3. Commit and push
4. Run `.\scripts\Sync-AllWorkspaces.ps1`
5. All workspaces get the new agent

### Update an Existing Instruction
1. Edit `.github/instructions/powershell-dev.instructions.md` in Workspace Main
2. Commit and push
3. Run `.\scripts\Sync-AllWorkspaces.ps1`
4. Workspaces pull updates within minutes

### Migrate Existing Workspace to GitHub
```powershell
.\scripts\Update-WorkspaceRepository.ps1 `
  -WorkspacePath "D:\COPilot Workspaces\Existing Workspace" `
  -CreateRepository $true
```

### Remove a Workspace from Management
1. Remove entry from `config/workspaces-config.json`
2. Optionally delete the workspace folder
3. GitHub repository remains unchanged

## Scripts Reference

### Initialize-AllWorkspaces.ps1
Initializes all workspaces listed in `config/workspaces-config.json`:
- Creates `.gitmodules` if missing
- Adds Workspace Main as `.github/` submodule
- Initializes Git for non-Git workspaces
- Configures `.copilot-instructions.md`

### Sync-AllWorkspaces.ps1
Synchronizes all workspaces:
- Pulls latest customizations from Workspace Main
- Updates `.github/` submodules
- Verifies agent/instruction files
- Reports sync status

### Create-NewWorkspace.ps1
Creates a new workspace from template:
- Generates workspace directory
- Copies template structure
- Initializes Git repository
- Adds customizations submodule
- Optionally creates GitHub repository

### Update-WorkspaceRepository.ps1
Updates a workspace's GitHub repository:
- Creates repository if needed
- Configures remote URL
- Commits current state
- Pushes to GitHub

## Automation & Integration

### GitHub Actions (Optional)
Potential workflows for auto-sync, PR checks, and deployment:
- Auto-sync agents/instructions on push
- Validate new agents before merge
- Create workspace repositories automatically

### Local Automation
- Watch script for real-time submodule updates
- Scheduled sync via Task Scheduler
- Pre-commit hooks to validate structure

## Security & Best Practices

✅ **DO:**
- Commit `.gitmodules` to track submodule versions
- Use specific agent names and clear descriptions
- Document custom agents in this workspace
- Review changes before syncing
- Use meaningful commit messages

❌ **DON'T:**
- Commit credentials or secrets
- Modify Workspace Main `.github/` from other workspaces
- Push directly to workspaces' main branches
- Delete workspace entries without verification

## Troubleshooting

### Agents not syncing
```powershell
# Check submodule status
git submodule status

# Reset submodule to latest
git submodule foreach git pull origin main

# Reinitialize
git submodule update --init --recursive
```

### GitHub push fails
```powershell
# Verify remote configuration
git remote -v

# Check authentication
gh auth status

# Update remote URL if needed
git remote set-url origin "https://github.com/dcrozier007/workspace-name.git"
```

### Workspace not syncing
1. Check workspace listed in `config/workspaces-config.json`
2. Verify path exists and is a Git repository
3. Ensure `.gitmodules` file is present
4. Run `.\scripts\Sync-AllWorkspaces.ps1 -Verbose`

## Support & Maintenance

- Review sync logs in `logs/` directory
- Check GitHub Actions workflows for automation errors
- Use `Sync-AllWorkspaces.ps1 -Report` for detailed status

## Related Documentation

- [Workspace Creation Guide](docs/WORKSPACE-CREATION.md)
- [GitHub Setup Guide](docs/GITHUB-SETUP.md)
- [Automation Guide](docs/AUTOMATION-GUIDE.md)
