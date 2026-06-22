#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Install custom skills for Claude Code and/or OpenCode
.DESCRIPTION
    This script installs custom skills to the appropriate directories for
    Claude Code and/or OpenCode. It also creates the global configuration file.
.PARAMETER Target
    Installation target: "claude", "opencode", or "all"
.PARAMETER SkipConfig
    Skip the interactive configuration setup
.EXAMPLE
    .\install.ps1 -Target claude
    .\install.ps1 -Target all
    .\install.ps1 -Target opencode -SkipConfig
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("claude", "opencode", "all")]
    [string]$Target = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfig
)

$ErrorActionPreference = "Stop"

# Source directory (where this script is located)
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Target directories
$GlobalConfigDir = Join-Path $env:USERPROFILE ".config\gs-skills"
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$OpenCodeSkillsDir = Join-Path $env:USERPROFILE ".config\opencode\skills"
$OpenCodeCommandsDir = Join-Path $env:USERPROFILE ".config\opencode\commands"

function Write-Step {
    param([string]$Message)
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "   $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "   Error: $Message" -ForegroundColor Red
}

function Test-NodeInstalled {
    try {
        $nodeVersion = node --version 2>$null
        return $true
    } catch {
        return $false
    }
}

function Install-GlobalConfig {
    Write-Step "Setting up global configuration"
    
    if (-not (Test-Path $GlobalConfigDir)) {
        New-Item -ItemType Directory -Path $GlobalConfigDir -Force | Out-Null
        Write-Success "Created config directory: $GlobalConfigDir"
    }
    
    $configPath = Join-Path $GlobalConfigDir "config.json"
    
    if (Test-Path $configPath) {
        Write-Warning "Config file already exists at: $configPath"
        $overwrite = Read-Host "   Do you want to overwrite it? (y/N)"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Warning "Keeping existing config"
            return
        }
    }
    
    if ($SkipConfig) {
        Write-Warning "Skipping interactive config (using example template)"
        $exampleConfigPath = Join-Path $SourceDir "config.example.json"
        if (Test-Path $exampleConfigPath) {
            Copy-Item -Path $exampleConfigPath -Destination $configPath -Force
            Write-Success "Copied example config to: $configPath"
            Write-Warning "Please edit $configPath with your actual credentials"
            return
        } else {
            $config = @{
                jira = @{
                    base_url = ""
                    pat = ""
                    default_project = ""
                }
            }
        }
    } else {
        Write-Host ""
        Write-Host "   Please provide your Jira configuration:" -ForegroundColor White
        Write-Host "   (Press Enter to skip any field)" -ForegroundColor Gray
        Write-Host ""
        
        $baseUrl = Read-Host "   Jira Base URL (e.g., https://jira.company.com)"
        $pat = Read-Host "   Personal Access Token"
        $defaultProject = Read-Host "   Default Project Key (optional)"
        
        $config = @{
            jira = @{
                base_url = $baseUrl
                pat = $pat
                default_project = $defaultProject
            }
        }
    }
    
    $config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
    Write-Success "Configuration saved to: $configPath"
}

function Install-LibFiles {
    Write-Step "Installing library files"
    
    $libTargetDir = Join-Path $GlobalConfigDir "lib"
    if (-not (Test-Path $libTargetDir)) {
        New-Item -ItemType Directory -Path $libTargetDir -Force | Out-Null
    }
    
    $libSourceDir = Join-Path $SourceDir "lib"
    Copy-Item -Path "$libSourceDir\*" -Destination $libTargetDir -Recurse -Force
    Write-Success "Library files installed to: $libTargetDir"
}

function Install-SkillToDirectory {
    param(
        [string]$SkillName,
        [string]$TargetDir
    )
    
    $skillSourceDir = Join-Path $SourceDir "skills\$SkillName"
    $skillTargetDir = Join-Path $TargetDir $SkillName
    
    if (-not (Test-Path $skillTargetDir)) {
        New-Item -ItemType Directory -Path $skillTargetDir -Force | Out-Null
    }
    
    # Copy SKILL.md and replace placeholder with actual path
    $skillContent = Get-Content -Path "$skillSourceDir\SKILL.md" -Raw
    $jiraSkillsHome = $GlobalConfigDir -replace '\\', '/'
    $skillContent = $skillContent -replace '\{JIRA_SKILLS_HOME\}', $jiraSkillsHome
    
    Set-Content -Path "$skillTargetDir\SKILL.md" -Value $skillContent -Encoding UTF8
    Write-Success "Installed skill: $SkillName -> $skillTargetDir"
}

function Install-ClaudeSkills {
    Write-Step "Installing skills for Claude Code"
    
    if (-not (Test-Path $ClaudeSkillsDir)) {
        New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
    }
    
    $skills = @("jira-issues", "jira-projects", "jira-sprint", "code-security-check")
    foreach ($skill in $skills) {
        Install-SkillToDirectory -SkillName $skill -TargetDir $ClaudeSkillsDir
    }
}

function Install-OpenCodeSkills {
    Write-Step "Installing skills for OpenCode"
    
    if (-not (Test-Path $OpenCodeSkillsDir)) {
        New-Item -ItemType Directory -Path $OpenCodeSkillsDir -Force | Out-Null
    }
    
    $skills = @("jira-issues", "jira-projects", "jira-sprint", "code-security-check")
    foreach ($skill in $skills) {
        Install-SkillToDirectory -SkillName $skill -TargetDir $OpenCodeSkillsDir
    }
}

function Install-OpenCodeCommands {
    Write-Step "Installing commands for OpenCode"
    
    if (-not (Test-Path $OpenCodeCommandsDir)) {
        New-Item -ItemType Directory -Path $OpenCodeCommandsDir -Force | Out-Null
    }
    
    $commandsSourceDir = Join-Path $SourceDir "commands"
    if (Test-Path $commandsSourceDir) {
        Copy-Item -Path "$commandsSourceDir\*" -Destination $OpenCodeCommandsDir -Force
        Write-Success "Commands installed to: $OpenCodeCommandsDir"
    } else {
        Write-Warning "No commands directory found in source"
    }
}

function Test-Installation {
    Write-Step "Verifying installation"
    
    # Check Node.js
    if (Test-NodeInstalled) {
        $nodeVersion = node --version
        Write-Success "Node.js installed: $nodeVersion"
    } else {
        Write-ErrorMsg "Node.js is not installed. Please install Node.js first."
        return $false
    }
    
    # Check config file
    $configPath = Join-Path $GlobalConfigDir "config.json"
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        if ($config.jira.base_url -and $config.jira.pat) {
            Write-Success "Configuration is set up"
        } else {
            Write-Warning "Configuration is incomplete (jira.base_url or jira.pat missing)"
        }
    } else {
        Write-Warning "No configuration file found"
    }
    
    # Check lib files
    $libDir = Join-Path $GlobalConfigDir "lib"
    if (Test-Path "$libDir\jira.js") {
        Write-Success "Library files installed"
    } else {
        Write-ErrorMsg "Library files not found"
        return $false
    }
    
    return $true
}

# Main installation
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  My Skills Installer" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Check Node.js
if (-not (Test-NodeInstalled)) {
    Write-ErrorMsg "Node.js is required but not installed."
    Write-Host "   Please install Node.js from https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Install global config and lib
Install-GlobalConfig
Install-LibFiles

# Install skills based on target
switch ($Target) {
    "claude" {
        Install-ClaudeSkills
    }
    "opencode" {
        Install-OpenCodeSkills
        Install-OpenCodeCommands
    }
    "all" {
        Install-ClaudeSkills
        Install-OpenCodeSkills
        Install-OpenCodeCommands
    }
}

# Verify installation
$installOk = Test-Installation

if ($installOk) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Installation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed to:" -ForegroundColor White
    Write-Host "  Config:  $GlobalConfigDir" -ForegroundColor Gray
    Write-Host "  Lib:     $GlobalConfigDir\lib" -ForegroundColor Gray
    if ($Target -eq "claude" -or $Target -eq "all") {
        Write-Host "  Claude:  $ClaudeSkillsDir" -ForegroundColor Gray
    }
    if ($Target -eq "opencode" -or $Target -eq "all") {
        Write-Host "  OpenCode: $OpenCodeSkillsDir" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Restart Claude Code or OpenCode to use the new skills." -ForegroundColor Yellow
} else {
    Write-Host "`nInstallation completed with errors. Please check the messages above." -ForegroundColor Red
}
