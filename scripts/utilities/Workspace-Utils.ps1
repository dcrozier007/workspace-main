<#
    Workspace-Utils.ps1
    
    Utility functions for workspace management and Git operations
#>

function Get-WorkspaceRegistry {
    <#
    .SYNOPSIS
    Load workspace registry from config file
    #>
    param(
        [string]$RegistryPath = "config\workspaces-config.json"
    )
    
    if (-not (Test-Path $RegistryPath)) {
        Write-Error "Workspace registry not found: $RegistryPath"
        return $null
    }
    
    try {
        $content = Get-Content $RegistryPath -Raw
        return $content | ConvertFrom-Json
    } catch {
        Write-Error "Failed to parse workspace registry: $_"
        return $null
    }
}

function Save-WorkspaceRegistry {
    <#
    .SYNOPSIS
    Save workspace registry to config file
    #>
    param(
        [object]$Registry,
        [string]$RegistryPath = "config\workspaces-config.json"
    )
    
    try {
        $json = $Registry | ConvertTo-Json -Depth 10
        Set-Content -Path $RegistryPath -Value $json -Encoding UTF8
        return $true
    } catch {
        Write-Error "Failed to save workspace registry: $_"
        return $false
    }
}

function Get-RepositoryStatus {
    <#
    .SYNOPSIS
    Get Git status for a repository (commits behind/ahead)
    #>
    param(
        [string]$RepositoryPath
    )
    
    if (-not (Test-Path (Join-Path $RepositoryPath ".git"))) {
        return @{ isGitRepo = $false }
    }
    
    Push-Location $RepositoryPath
    
    try {
        # Get current branch
        $branch = & git branch --show-current 2>$null
        if ($LASTEXITCODE -ne 0) {
            return @{ isGitRepo = $true; branch = "DETACHED"; error = "detached HEAD" }
        }
        
        # Get remote
        $remote = & git remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0) {
            $remote = "NO_REMOTE"
        }
        
        # Fetch latest from remote
        if ($remote -ne "NO_REMOTE") {
            & git fetch origin -q 2>$null
        }
        
        # Count commits
        $behind = & git rev-list --count HEAD..origin/$branch 2>$null
        if ($LASTEXITCODE -ne 0) { $behind = 0 }
        
        $ahead = & git rev-list --count origin/$branch..HEAD 2>$null
        if ($LASTEXITCODE -ne 0) { $ahead = 0 }
        
        # Get last commit info
        $lastCommit = & git log -1 --format="%h %s" 2>$null
        $lastCommitDate = & git log -1 --format="%ai" 2>$null
        
        # Check for uncommitted changes
        $status = & git status --porcelain 2>$null
        $hasChanges = -not [string]::IsNullOrEmpty($status)
        
        return @{
            isGitRepo = $true
            branch = $branch.Trim()
            remote = $remote
            behind = [int]$behind
            ahead = [int]$ahead
            hasChanges = $hasChanges
            lastCommit = $lastCommit.Trim()
            lastCommitDate = $lastCommitDate.Trim()
        }
    } catch {
        return @{ isGitRepo = $true; error = $_.Message }
    } finally {
        Pop-Location
    }
}

function Pull-LatestFromRemote {
    <#
    .SYNOPSIS
    Pull latest changes from remote repository
    #>
    param(
        [string]$RepositoryPath,
        [bool]$Force = $false
    )
    
    if (-not (Test-Path (Join-Path $RepositoryPath ".git"))) {
        Write-Error "Not a Git repository: $RepositoryPath"
        return $false
    }
    
    Push-Location $RepositoryPath
    
    try {
        $branch = & git branch --show-current 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Could not determine current branch"
            return $false
        }
        
        if ($Force) {
            & git fetch origin $branch -q
            & git reset --hard origin/$branch
        } else {
            & git pull origin $branch -q
        }
        
        if ($LASTEXITCODE -eq 0) {
            return $true
        } else {
            return $false
        }
    } catch {
        Write-Error "Error pulling from remote: $_"
        return $false
    } finally {
        Pop-Location
    }
}

function Initialize-GitRepository {
    <#
    .SYNOPSIS
    Initialize a directory as a Git repository
    #>
    param(
        [string]$RepositoryPath,
        [string]$RemoteUrl
    )
    
    if (-not (Test-Path $RepositoryPath)) {
        Write-Error "Path does not exist: $RepositoryPath"
        return $false
    }
    
    Push-Location $RepositoryPath
    
    try {
        # Initialize if not already a repo
        if (-not (Test-Path ".git")) {
            & git init -q
            & git config user.name "Copilot"
            & git config user.email "223556219+Copilot@users.noreply.github.com"
        }
        
        # Add remote if provided
        if ($RemoteUrl) {
            $existingRemote = & git remote get-url origin 2>$null
            if ($LASTEXITCODE -ne 0) {
                & git remote add origin $RemoteUrl
            } else {
                & git remote set-url origin $RemoteUrl
            }
        }
        
        # Create initial commit if needed
        $status = & git status --porcelain 2>$null
        if (-not [string]::IsNullOrEmpty($status)) {
            & git add .
            & git commit -m "Initial commit" -q 2>$null
        }
        
        return $true
    } catch {
        Write-Error "Error initializing repository: $_"
        return $false
    } finally {
        Pop-Location
    }
}
