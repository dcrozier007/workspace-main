<#
    Migrate-WorkspacesToGitHub.ps1
    
    Migrates existing workspaces to GitHub repositories
    - Creates GitHub repositories
    - Initializes Git for non-Git workspaces
    - Pushes initial commit
    - Updates workspace registry
#>

param(
    [string]$WorkspacesParentPath = "D:\COPilot Workspaces",
    [string]$GitHubOwner = "dcrozier007"
)

# Import utilities
. "$PSScriptRoot\utilities\GitHub-Utils.ps1"
. "$PSScriptRoot\utilities\Workspace-Utils.ps1"

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Migrate Workspaces to GitHub" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "This will create GitHub repositories for workspaces and push their content`n"

# Verify GitHub auth
if (-not (Test-GitHubAuth)) {
    exit 1
}

# Load registry
$registryPath = Join-Path $PSScriptRoot "..\config\workspaces-config.json"
$registry = Get-WorkspaceRegistry -RegistryPath $registryPath

if (-not $registry) {
    Write-Error "Could not load workspace registry"
    exit 1
}

$createdCount = 0
$skippedCount = 0
$errorCount = 0

foreach ($workspace in $registry.workspaces) {
    $wsName = $workspace.name
    $wsPath = $workspace.path
    
    if (-not (Test-Path $wsPath)) {
        Write-Host "[SKIP] $wsName (path not found)" -ForegroundColor Yellow
        $skippedCount++
        continue
    }
    
    # Determine repository name from workspace name
    $repoName = "copilot-$($wsName.ToLower() -replace '\s+', '-' -replace '[^a-z0-9-]', '')"
    
    # Check if already has GitHub remote
    $status = Get-RepositoryStatus -RepositoryPath $wsPath
    if ($status.isGitRepo -and $status.remote -ne "NO_REMOTE" -and $status.remote -like "*github.com*") {
        Write-Host "[SKIP] $wsName (already has GitHub remote)" -ForegroundColor Green
        $skippedCount++
        continue
    }
    
    # Check if repository already exists
    if (Test-RepositoryExists -Owner $GitHubOwner -RepositoryName $repoName) {
        Write-Host "[EXISTS] $wsName -> $repoName" -ForegroundColor Cyan
        
        # Update local repository with remote
        $remoteUrl = Get-GitHubRepositoryUrl -Owner $GitHubOwner -RepositoryName $repoName
        Initialize-GitRepository -RepositoryPath $wsPath -RemoteUrl $remoteUrl
        
        $workspace.github = @{
            owner = $GitHubOwner
            repo = $repoName
            url = $remoteUrl
        }
        $skippedCount++
        continue
    }
    
    Write-Host "Creating: $wsName -> $repoName..." -ForegroundColor Yellow
    
    # Create GitHub repository
    if (-not (Create-GitHubRepository -RepositoryName $repoName -Description "Copilot workspace: $wsName")) {
        Write-Host "[FAILED] Could not create GitHub repository for $wsName" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    # Initialize local Git repository
    $remoteUrl = Get-GitHubRepositoryUrl -Owner $GitHubOwner -RepositoryName $repoName
    if (-not (Initialize-GitRepository -RepositoryPath $wsPath -RemoteUrl $remoteUrl)) {
        Write-Host "[FAILED] Could not initialize local repository for $wsName" -ForegroundColor Red
        $errorCount++
        continue
    }
    
    # Push to GitHub
    Push-Location $wsPath
    try {
        & git branch -M main -q 2>$null
        & git push -u origin main -q 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[CREATED] $wsName -> $repoName" -ForegroundColor Green
            $createdCount++
            
            # Update registry
            $workspace.github = @{
                owner = $GitHubOwner
                repo = $repoName
                url = $remoteUrl
            }
        } else {
            Write-Host "[FAILED] Could not push to GitHub for $wsName" -ForegroundColor Red
            $errorCount++
        }
    } catch {
        Write-Host "[FAILED] Error pushing $wsName : $_" -ForegroundColor Red
        $errorCount++
    } finally {
        Pop-Location
    }
}

# Save updated registry
Save-WorkspaceRegistry -Registry $registry -RegistryPath $registryPath

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Migration Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "[CREATED] $createdCount" -ForegroundColor Green
Write-Host "[SKIPPED] $skippedCount" -ForegroundColor Cyan
Write-Host "[FAILED] $errorCount" -ForegroundColor Red
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "Migration complete! All workspaces are now on GitHub." -ForegroundColor Green
} else {
    Write-Host "Migration completed with errors. Please review and retry." -ForegroundColor Yellow
}
