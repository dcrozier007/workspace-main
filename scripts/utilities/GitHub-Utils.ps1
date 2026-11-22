<#
    GitHub-Utils.ps1
    
    Utility functions for GitHub repository management and verification
#>

function Test-GitHubAuth {
    <#
    .SYNOPSIS
    Verify GitHub CLI authentication
    #>
    try {
        $output = & gh auth status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] GitHub authenticated" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] GitHub authentication required" -ForegroundColor Red
            Write-Host "Run: gh auth login" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "[ERROR] GitHub CLI not installed or not accessible" -ForegroundColor Red
        return $false
    }
}

function Create-GitHubRepository {
    <#
    .SYNOPSIS
    Create a new repository on GitHub
    #>
    param(
        [string]$RepositoryName,
        [string]$Description = "",
        [bool]$Public = $true
    )
    
    if (-not (Test-GitHubAuth)) {
        return $false
    }
    
    try {
        $visibility = if ($Public) { "public" } else { "private" }
        $output = & gh repo create $RepositoryName --$visibility --description "$Description" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Repository created: $RepositoryName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[FAILED] Failed to create repository: $output" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[ERROR] Error creating repository: $_" -ForegroundColor Red
        return $false
    }
}

function Get-GitHubRepositoryUrl {
    <#
    .SYNOPSIS
    Get HTTPS URL for a GitHub repository
    #>
    param(
        [string]$Owner = "dcrozier007",
        [string]$RepositoryName
    )
    
    return "https://github.com/$Owner/$RepositoryName.git"
}

function Test-RepositoryExists {
    <#
    .SYNOPSIS
    Check if repository exists on GitHub
    #>
    param(
        [string]$Owner = "dcrozier007",
        [string]$RepositoryName
    )
    
    try {
        $output = & gh repo view "$Owner/$RepositoryName" 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}
