<#
    Pull-LatestFromAllWorkspaces.ps1
    
    Pulls latest changes from GitHub for all workspaces
    Ensures all workspaces are at the current remote version
#>

param(
    [string]$WorkspacesParentPath = "D:\COPilot Workspaces",
    [switch]$Force,
    [switch]$Quiet
)

# Import utilities
. "$PSScriptRoot\utilities\GitHub-Utils.ps1"
. "$PSScriptRoot\utilities\Workspace-Utils.ps1"

if (-not $Quiet) {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "Pulling Latest from All Workspaces" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
}

# Load registry
$registryPath = Join-Path $PSScriptRoot "..\config\workspaces-config.json"
$registry = Get-WorkspaceRegistry -RegistryPath $registryPath

if (-not $registry) {
    Write-Error "Could not load workspace registry"
    exit 1
}

$successCount = 0
$failureCount = 0
$skippedCount = 0
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

foreach ($workspace in $registry.workspaces) {
    $wsPath = $workspace.path
    $wsName = $workspace.name
    
    if (-not (Test-Path $wsPath)) {
        if (-not $Quiet) {
            Write-Host "[SKIP] $wsName (path not found)" -ForegroundColor Yellow
        }
        $skippedCount++
        continue
    }
    
    $status = Get-RepositoryStatus -RepositoryPath $wsPath
    
    if (-not $status.isGitRepo) {
        if (-not $Quiet) {
            Write-Host "[SKIP] $wsName (not a Git repository)" -ForegroundColor Yellow
        }
        $skippedCount++
        continue
    }
    
    if ($status.remote -eq "NO_REMOTE") {
        if (-not $Quiet) {
            Write-Host "[SKIP] $wsName (no GitHub remote)" -ForegroundColor Yellow
        }
        $skippedCount++
        continue
    }
    
    # Check if behind
    if ($status.behind -eq 0 -and -not $Force) {
        if (-not $Quiet) {
            Write-Host "[OK] $wsName (already up-to-date)" -ForegroundColor Green
        }
        $successCount++
        continue
    }
    
    # Pull latest
    if (-not $Quiet) {
        Write-Host "[PULLING] $wsName..." -ForegroundColor Cyan
    }
    
    if (Pull-LatestFromRemote -RepositoryPath $wsPath -Force $Force) {
        if (-not $Quiet) {
            Write-Host "[OK] $wsName (pulled successfully)" -ForegroundColor Green
        }
        $successCount++
        
        # Update registry timestamp
        $workspace.lastSync = $timestamp
    } else {
        Write-Host "[FAILED] $wsName (pull failed)" -ForegroundColor Red
        $failureCount++
    }
}

# Summary
if (-not $Quiet) {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "Pull Summary" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "[OK] Successful: $successCount" -ForegroundColor Green
    Write-Host "[FAILED] Failed: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Green" })
    Write-Host "[SKIPPED] Skipped: $skippedCount" -ForegroundColor Yellow
    Write-Host ""
}

# Save updated registry
Save-WorkspaceRegistry -Registry $registry -RegistryPath $registryPath

if ($failureCount -gt 0) {
    exit 1
} else {
    exit 0
}
