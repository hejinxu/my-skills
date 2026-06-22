#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Uninstall custom skills for Claude Code and/or OpenCode
.DESCRIPTION
    This script removes custom skills from the appropriate directories for
    Claude Code and/or OpenCode. It optionally removes the global configuration.
.PARAMETER Target
    Uninstallation target: "claude", "opencode", or "all"
.PARAMETER KeepConfig
    Keep the global configuration file (~/.config/gs-skills/config.json)
.EXAMPLE
    .\uninstall.ps1 -Target claude
    .\uninstall.ps1 -Target all
    .\uninstall.ps1 -Target opencode -KeepConfig
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("claude", "opencode", "all")]
    [string]$Target = "all",
    
    [Parameter(Mandatory=$false)]
    [switch]$KeepConfig
)

$ErrorActionPreference = "Stop"

# Target directories
$GlobalConfigDir = Join-Path $env:USERPROFILE ".config\gs-skills"
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$OpenCodeSkillsDir = Join-Path $env:USERPROFILE ".config\opencode\skills"
$OpenCodeCommandsDir = Join-Path $env:USERPROFILE ".config\opencode\commands"

$Skills = @("jira-issues", "jira-projects", "jira-sprint", "code-security-check")

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

function Remove-SkillFromDirectory {
    param(
        [string]$SkillName,
        [string]$TargetDir
    )
    
    $skillDir = Join-Path $TargetDir $SkillName
    if (Test-Path $skillDir) {
        Remove-Item -Path $skillDir -Recurse -Force
        Write-Success "Removed skill: $SkillName from $TargetDir"
    } else {
        Write-Warning "Skill not found: $SkillName in $TargetDir"
    }
}

function Uninstall-ClaudeSkills {
    Write-Step "Uninstalling skills for Claude Code"
    
    foreach ($skill in $Skills) {
        Remove-SkillFromDirectory -SkillName $skill -TargetDir $ClaudeSkillsDir
    }
}

function Uninstall-OpenCodeSkills {
    Write-Step "Uninstalling skills for OpenCode"
    
    foreach ($skill in $Skills) {
        Remove-SkillFromDirectory -SkillName $skill -TargetDir $OpenCodeSkillsDir
    }
}

function Uninstall-OpenCodeCommands {
    Write-Step "Uninstalling commands for OpenCode"
    
    foreach ($skill in $Skills) {
        $commandFile = Join-Path $OpenCodeCommandsDir "$skill.md"
        if (Test-Path $commandFile) {
            Remove-Item -Path $commandFile -Force
            Write-Success "Removed command: $skill.md"
        } else {
            Write-Warning "Command not found: $skill.md"
        }
    }
}

function Uninstall-GlobalConfig {
    Write-Step "Removing global configuration"
    
    if ($KeepConfig) {
        Write-Warning "Keeping configuration (--KeepConfig flag set)"
        return
    }
    
    if (Test-Path $GlobalConfigDir) {
        Remove-Item -Path $GlobalConfigDir -Recurse -Force
        Write-Success "Removed config directory: $GlobalConfigDir"
    } else {
        Write-Warning "Config directory not found: $GlobalConfigDir"
    }
}

function Test-Uninstallation {
    Write-Step "Verifying uninstallation"
    
    $allClean = $true
    
    # Check config
    if (-not $KeepConfig -and (Test-Path $GlobalConfigDir)) {
        Write-Warning "Config directory still exists"
        $allClean = $false
    }
    
    # Check Claude skills
    foreach ($skill in $Skills) {
        $skillDir = Join-Path $ClaudeSkillsDir $skill
        if (Test-Path $skillDir) {
            Write-Warning "Claude skill still exists: $skill"
            $allClean = $false
        }
    }
    
    # Check OpenCode skills
    foreach ($skill in $Skills) {
        $skillDir = Join-Path $OpenCodeSkillsDir $skill
        if (Test-Path $skillDir) {
            Write-Warning "OpenCode skill still exists: $skill"
            $allClean = $false
        }
    }
    
    # Check OpenCode commands
    foreach ($skill in $Skills) {
        $commandFile = Join-Path $OpenCodeCommandsDir "$skill.md"
        if (Test-Path $commandFile) {
            Write-Warning "OpenCode command still exists: $skill.md"
            $allClean = $false
        }
    }
    
    return $allClean
}

# Main uninstallation
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  My Skills Uninstaller" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# Uninstall based on target
switch ($Target) {
    "claude" {
        Uninstall-ClaudeSkills
    }
    "opencode" {
        Uninstall-OpenCodeSkills
        Uninstall-OpenCodeCommands
    }
    "all" {
        Uninstall-ClaudeSkills
        Uninstall-OpenCodeSkills
        Uninstall-OpenCodeCommands
        Uninstall-GlobalConfig
    }
}

# Verify uninstallation
$uninstallOk = Test-Uninstallation

if ($uninstallOk) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Uninstallation Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Removed from:" -ForegroundColor White
    if ($Target -eq "claude" -or $Target -eq "all") {
        Write-Host "  Claude:  $ClaudeSkillsDir" -ForegroundColor Gray
    }
    if ($Target -eq "opencode" -or $Target -eq "all") {
        Write-Host "  OpenCode: $OpenCodeSkillsDir" -ForegroundColor Gray
        Write-Host "  Commands: $OpenCodeCommandsDir" -ForegroundColor Gray
    }
    if ($Target -eq "all" -and -not $KeepConfig) {
        Write-Host "  Config:  $GlobalConfigDir" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Restart Claude Code or OpenCode to apply changes." -ForegroundColor Yellow
} else {
    Write-Host "`nUninstallation completed with warnings. Please check the messages above." -ForegroundColor Yellow
}
