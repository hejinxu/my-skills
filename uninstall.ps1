#!/usr/bin/env pwsh

<#
.SYNOPSIS
    卸载 Claude Code 和/或 OpenCode 的自定义 skills
.DESCRIPTION
    此脚本从相应目录中移除 Claude Code 和/或 OpenCode 的自定义 skills。
    可选择是否保留全局配置文件。
.PARAMETER Target
    卸载目标："claude"、"opencode" 或 "all"
.PARAMETER KeepConfig
    保留全局配置文件（~/.config/gs-skills/config.json）
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

# 目标目录
$GlobalConfigDir = Join-Path $env:USERPROFILE ".config\gs-skills"
$ClaudeSkillsDir = Join-Path $env:USERPROFILE ".claude\skills"
$OpenCodeSkillsDir = Join-Path $env:USERPROFILE ".config\opencode\skills"
$OpenCodeCommandsDir = Join-Path $env:USERPROFILE ".config\opencode\commands"

$Skills = @("jira-issues", "jira-projects", "jira-sprint", "code-security-check", "git-diff", "git-restore", "git-status", "git-log", "git-blame", "git-stash", "git-commit")

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

function Get-UninstallPreview {
    $preview = @()
    
    if ($Target -eq "claude" -or $Target -eq "all") {
        foreach ($skill in $Skills) {
            $skillDir = Join-Path $ClaudeSkillsDir $skill
            if (Test-Path $skillDir) {
                $preview += "  [Claude] skills/$skill/"
            }
        }
    }
    
    if ($Target -eq "opencode" -or $Target -eq "all") {
        foreach ($skill in $Skills) {
            $skillDir = Join-Path $OpenCodeSkillsDir $skill
            if (Test-Path $skillDir) {
                $preview += "  [OpenCode] skills/$skill/"
            }
            $commandFile = Join-Path $OpenCodeCommandsDir "$skill.md"
            if (Test-Path $commandFile) {
                $preview += "  [OpenCode] commands/$skill.md"
            }
        }
    }
    
    if ($Target -eq "all" -and -not $KeepConfig) {
        if (Test-Path $GlobalConfigDir) {
            $preview += "  [配置] $GlobalConfigDir"
        }
    }
    
    return $preview
}

function Show-UninstallPreview {
    Write-Step "将要卸载以下内容："
    
    $preview = Get-UninstallPreview
    
    if ($preview.Count -eq 0) {
        Write-Warning "没有找到已安装的 skills"
        return $false
    }
    
    foreach ($item in $preview) {
        Write-Host $item -ForegroundColor White
    }
    
    Write-Host ""
    $confirm = Read-Host "确认要卸载以上内容吗？(y/N)"
    
    return ($confirm -eq "y" -or $confirm -eq "Y")
}

function Remove-SkillFromDirectory {
    param(
        [string]$SkillName,
        [string]$TargetDir
    )
    
    $skillDir = Join-Path $TargetDir $SkillName
    if (Test-Path $skillDir) {
        Remove-Item -Path $skillDir -Recurse -Force
        Write-Success "已移除: $SkillName"
    }
}

function Uninstall-ClaudeSkills {
    Write-Step "卸载 Claude Code skills"
    
    foreach ($skill in $Skills) {
        Remove-SkillFromDirectory -SkillName $skill -TargetDir $ClaudeSkillsDir
    }
}

function Uninstall-OpenCodeSkills {
    Write-Step "卸载 OpenCode skills"
    
    foreach ($skill in $Skills) {
        Remove-SkillFromDirectory -SkillName $skill -TargetDir $OpenCodeSkillsDir
    }
}

function Uninstall-OpenCodeCommands {
    Write-Step "卸载 OpenCode commands"
    
    foreach ($skill in $Skills) {
        $commandFile = Join-Path $OpenCodeCommandsDir "$skill.md"
        if (Test-Path $commandFile) {
            Remove-Item -Path $commandFile -Force
            Write-Success "已移除: $skill.md"
        }
    }
}

function Uninstall-GlobalConfig {
    if ($KeepConfig) {
        Write-Warning "保留配置文件（已指定 -KeepConfig 参数）"
        return
    }
    
    if (Test-Path $GlobalConfigDir) {
        Write-Host ""
        Write-Host "   配置目录: $GlobalConfigDir" -ForegroundColor White
        $confirm = Read-Host "   是否删除配置文件？(y/N)"
        if ($confirm -eq "y" -or $confirm -eq "Y") {
            Remove-Item -Path $GlobalConfigDir -Recurse -Force
            Write-Success "已删除配置目录"
        } else {
            Write-Warning "保留配置文件"
        }
    }
}

function Test-Uninstallation {
    Write-Step "验证卸载结果"
    
    $allClean = $true
    
    # 检查 Claude skills
    foreach ($skill in $Skills) {
        $skillDir = Join-Path $ClaudeSkillsDir $skill
        if (Test-Path $skillDir) {
            Write-Warning "Claude skill 仍存在: $skill"
            $allClean = $false
        }
    }
    
    # 检查 OpenCode skills
    foreach ($skill in $Skills) {
        $skillDir = Join-Path $OpenCodeSkillsDir $skill
        if (Test-Path $skillDir) {
            Write-Warning "OpenCode skill 仍存在: $skill"
            $allClean = $false
        }
    }
    
    # 检查 OpenCode commands
    foreach ($skill in $Skills) {
        $commandFile = Join-Path $OpenCodeCommandsDir "$skill.md"
        if (Test-Path $commandFile) {
            Write-Warning "OpenCode command 仍存在: $skill.md"
            $allClean = $false
        }
    }
    
    # 检查配置目录
    if (-not $KeepConfig -and (Test-Path $GlobalConfigDir)) {
        Write-Warning "配置目录仍存在"
        $allClean = $false
    }
    
    return $allClean
}

# 主流程
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Skills 卸载程序" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# 第一步：展示预览并确认
$confirmed = Show-UninstallPreview

if (-not $confirmed) {
    Write-Host "`n已取消卸载。" -ForegroundColor Yellow
    exit 0
}

# 第二步：执行卸载
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

# 第三步：验证卸载结果
$uninstallOk = Test-Uninstallation

if ($uninstallOk) {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  卸载完成！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "请重启 Claude Code 或 OpenCode 使更改生效。" -ForegroundColor Yellow
} else {
    Write-Host "`n卸载完成，但部分文件可能未完全移除。" -ForegroundColor Yellow
}
