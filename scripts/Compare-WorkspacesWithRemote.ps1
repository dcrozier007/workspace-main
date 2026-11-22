<#
    Compare-WorkspacesWithRemote.ps1
    
    Compares all workspaces with their GitHub remote versions
    Shows which workspaces are behind/ahead and need pulling
#>

param(
    [string]$WorkspacesParentPath = "D:\COPilot Workspaces",
    [switch]$Detailed
)

# Import utilities
. "$PSScriptRoot\utilities\GitHub-Utils.ps1"
. "$PSScriptRoot\utilities\Workspace-Utils.ps1"

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Workspace Sync Status Report" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Comparing local workspaces with GitHub remotes`n"

# Load registry
$registryPath = Join-Path $PSScriptRoot "..\config\workspaces-config.json"
$registry = Get-WorkspaceRegistry -RegistryPath $registryPath

if (-not $registry) {
    Write-Error "Could not load workspace registry"
    exit 1
}

$results = @()
$totalBehind = 0
$totalAhead = 0
$noRemote = 0

foreach ($workspace in $registry.workspaces) {
    $wsPath = $workspace.path
    
    if (-not (Test-Path $wsPath)) {
        Write-Host "[MISSING] $($workspace.name)" -ForegroundColor Yellow
        $results += @{
            name = $workspace.name
            status = "MISSING"
            behind = 0
            ahead = 0
        }
        continue
    }
    
    $status = Get-RepositoryStatus -RepositoryPath $wsPath
    
    if (-not $status.isGitRepo) {
        Write-Host "[NOT_GIT] $($workspace.name) (not a Git repository)" -ForegroundColor Yellow
        $results += @{
            name = $workspace.name
            status = "NOT_GIT"
            behind = 0
            ahead = 0
        }
        continue
    }
    
    if ($status.remote -eq "NO_REMOTE") {
        Write-Host "[NO_REMOTE] $($workspace.name) (no GitHub remote configured)" -ForegroundColor Yellow
        $noRemote++
        $results += @{
            name = $workspace.name
            status = "NO_REMOTE"
            behind = 0
            ahead = 0
        }
        continue
    }
    
    # Determine status
    $behindCount = $status.behind
    $aheadCount = $status.ahead
    $hasChanges = $status.hasChanges
    
    $totalBehind += $behindCount
    $totalAhead += $aheadCount
    
    # Display status
    if ($behindCount -gt 0) {
        Write-Host "[BEHIND] $($workspace.name) ($behindCount commits behind)" -ForegroundColor Red
        if ($Detailed) {
            Write-Host "  Branch: $($status.branch)" -ForegroundColor DarkGray
            Write-Host "  Remote: $($status.remote)" -ForegroundColor DarkGray
            Write-Host "  Last commit: $($status.lastCommit)" -ForegroundColor DarkGray
        }
    } elseif ($aheadCount -gt 0) {
        Write-Host "[AHEAD] $($workspace.name) ($aheadCount commits ahead)" -ForegroundColor Yellow
        if ($Detailed) {
            Write-Host "  Branch: $($status.branch)" -ForegroundColor DarkGray
            Write-Host "  Remote: $($status.remote)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "[OK] UP-TO-DATE: $($workspace.name)" -ForegroundColor Green
        if ($Detailed -and $hasChanges) {
            Write-Host "  [WARN] Has uncommitted changes" -ForegroundColor Yellow
        }
    }
    
    $results += @{
        name = $workspace.name
        status = if ($behindCount -gt 0) { "BEHIND" } elseif ($aheadCount -gt 0) { "AHEAD" } else { "UP_TO_DATE" }
        behind = $behindCount
        ahead = $aheadCount
    }
}

# Summary
Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Total workspaces checked: $($registry.workspaces.Count)" -ForegroundColor Cyan
Write-Host "Up-to-date: $($results | Where-Object { $_.status -eq 'UP_TO_DATE' } | Measure-Object).Count" -ForegroundColor Green
Write-Host "Behind (need pull): $($results | Where-Object { $_.status -eq 'BEHIND' } | Measure-Object).Count" -ForegroundColor Red
Write-Host "Ahead (need push): $($results | Where-Object { $_.status -eq 'AHEAD' } | Measure-Object).Count" -ForegroundColor Yellow
Write-Host "No remote: $noRemote" -ForegroundColor Yellow
Write-Host "Total commits behind: $totalBehind" -ForegroundColor Red
Write-Host ""

if ($totalBehind -gt 0) {
    Write-Host "[INFO] Run: .\Pull-LatestFromAllWorkspaces.ps1" -ForegroundColor Yellow
}
