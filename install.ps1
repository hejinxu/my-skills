#!/usr/bin/env pwsh

<#
.SYNOPSIS
    安装 Claude Code 和/或 OpenCode 的自定义 skills
.DESCRIPTION
    此脚本将自定义 skills 安装到相应目录，并创建全局配置文件。
.PARAMETER Target
    安装目标："claude"、"opencode" 或 "all"
.PARAMETER SkipConfig
    跳过交互式配置设置
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

# 源目录（脚本所在位置）
$SourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "   错误: $Message" -ForegroundColor Red
}

function Test-NodeInstalled {
    try {
        $nodeVersion = node --version 2>$null
        return $true
    } catch {
        return $false
    }
}

function Get-InstallPreview {
    $preview = @()
    
    $preview += "  [配置] $GlobalConfigDir\config.json"
    $preview += "  [库文件] $GlobalConfigDir\lib\*"
    
    if ($Target -eq "claude" -or $Target -eq "all") {
        foreach ($skill in $Skills) {
            $preview += "  [Claude] skills/$skill/"
        }
    }
    
    if ($Target -eq "opencode" -or $Target -eq "all") {
        foreach ($skill in $Skills) {
            $preview += "  [OpenCode] skills/$skill/"
            $preview += "  [OpenCode] commands/$skill.md"
        }
    }
    
    return $preview
}

function Show-InstallPreview {
    Write-Step "将要安装以下内容："
    
    $preview = Get-InstallPreview
    
    foreach ($item in $preview) {
        Write-Host $item -ForegroundColor White
    }
    
    Write-Host ""
    $confirm = Read-Host "确认要安装以上内容吗？(Y/n)"
    
    return ($confirm -ne "n" -and $confirm -ne "N")
}

function Install-GlobalConfig {
    Write-Step "设置全局配置"
    
    if (-not (Test-Path $GlobalConfigDir)) {
        New-Item -ItemType Directory -Path $GlobalConfigDir -Force | Out-Null
        Write-Success "已创建配置目录: $GlobalConfigDir"
    }
    
    $configPath = Join-Path $GlobalConfigDir "config.json"
    
    if (Test-Path $configPath) {
        Write-Warning "配置文件已存在: $configPath"
        $overwrite = Read-Host "   是否覆盖？(y/N)"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Warning "保留现有配置"
            return
        }
    }
    
    if ($SkipConfig) {
        Write-Warning "跳过交互式配置（使用示例模板）"
        $exampleConfigPath = Join-Path $SourceDir "config.example.json"
        if (Test-Path $exampleConfigPath) {
            Copy-Item -Path $exampleConfigPath -Destination $configPath -Force
            Write-Success "已复制示例配置到: $configPath"
            Write-Warning "请编辑 $configPath 填入您的实际配置"
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
        Write-Host "   请提供您的 Jira 配置：" -ForegroundColor White
        Write-Host "   （按回车可跳过任何字段）" -ForegroundColor Gray
        Write-Host ""
        
        $baseUrl = Read-Host "   Jira 地址（如 https://jira.company.com）"
        $pat = Read-Host "   个人访问令牌 (PAT)"
        $defaultProject = Read-Host "   默认项目键（可选）"
        
        $config = @{
            jira = @{
                base_url = $baseUrl
                pat = $pat
                default_project = $defaultProject
            }
        }
    }
    
    $config | ConvertTo-Json | Set-Content -Path $configPath -Encoding UTF8
    Write-Success "配置已保存到: $configPath"
}

function Install-LibFiles {
    Write-Step "安装库文件"
    
    $libTargetDir = Join-Path $GlobalConfigDir "lib"
    if (-not (Test-Path $libTargetDir)) {
        New-Item -ItemType Directory -Path $libTargetDir -Force | Out-Null
    }
    
    $libSourceDir = Join-Path $SourceDir "lib"
    Copy-Item -Path "$libSourceDir\*" -Destination $libTargetDir -Recurse -Force
    Write-Success "库文件已安装到: $libTargetDir"
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
    
    # 复制 SKILL.md 并替换占位符
    $skillContent = Get-Content -Path "$skillSourceDir\SKILL.md" -Raw
    $jiraSkillsHome = $GlobalConfigDir -replace '\\', '/'
    $skillContent = $skillContent -replace '\{JIRA_SKILLS_HOME\}', $jiraSkillsHome
    
    Set-Content -Path "$skillTargetDir\SKILL.md" -Value $skillContent -Encoding UTF8
}

function Install-ClaudeSkills {
    Write-Step "安装 Claude Code skills"
    
    if (-not (Test-Path $ClaudeSkillsDir)) {
        New-Item -ItemType Directory -Path $ClaudeSkillsDir -Force | Out-Null
    }
    
    foreach ($skill in $Skills) {
        Install-SkillToDirectory -SkillName $skill -TargetDir $ClaudeSkillsDir
        Write-Success "已安装: $skill"
    }
}

function Install-OpenCodeSkills {
    Write-Step "安装 OpenCode skills"
    
    if (-not (Test-Path $OpenCodeSkillsDir)) {
        New-Item -ItemType Directory -Path $OpenCodeSkillsDir -Force | Out-Null
    }
    
    foreach ($skill in $Skills) {
        Install-SkillToDirectory -SkillName $skill -TargetDir $OpenCodeSkillsDir
        Write-Success "已安装: $skill"
    }
}

function Install-OpenCodeCommands {
    Write-Step "安装 OpenCode commands"
    
    if (-not (Test-Path $OpenCodeCommandsDir)) {
        New-Item -ItemType Directory -Path $OpenCodeCommandsDir -Force | Out-Null
    }
    
    $commandsSourceDir = Join-Path $SourceDir "commands"
    if (Test-Path $commandsSourceDir) {
        Copy-Item -Path "$commandsSourceDir\*" -Destination $OpenCodeCommandsDir -Force
        Get-ChildItem "$commandsSourceDir\*.md" | ForEach-Object {
            Write-Success "已安装: $($_.Name)"
        }
    } else {
        Write-Warning "未找到 commands 目录"
    }
}

function Show-InstallSummary {
    param(
        [string]$Target,
        [bool]$Success
    )
    
    Write-Host "`n========================================" -ForegroundColor $(if ($Success) { "Green" } else { "Red" })
    Write-Host "  $(if ($Success) { "安装完成！" } else { "安装完成，但有错误" })" -ForegroundColor $(if ($Success) { "Green" } else { "Red" })
    Write-Host "========================================" -ForegroundColor $(if ($Success) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "已安装到：" -ForegroundColor White
    
    Write-Host "  配置目录: $GlobalConfigDir" -ForegroundColor Gray
    Write-Host "  库文件:   $GlobalConfigDir\lib" -ForegroundColor Gray
    
    if ($Target -eq "claude" -or $Target -eq "all") {
        Write-Host "  Claude:   $ClaudeSkillsDir" -ForegroundColor Gray
    }
    
    if ($Target -eq "opencode" -or $Target -eq "all") {
        Write-Host "  OpenCode: $OpenCodeSkillsDir" -ForegroundColor Gray
        Write-Host "  Commands: $OpenCodeCommandsDir" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "已安装的 skills：" -ForegroundColor White
    foreach ($skill in $Skills) {
        Write-Host "  - $skill" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "请重启 Claude Code 或 OpenCode 以使用新 skills。" -ForegroundColor Yellow
}

function Test-Installation {
    Write-Step "验证安装"
    
    # 检查 Node.js
    if (Test-NodeInstalled) {
        $nodeVersion = node --version
        Write-Success "Node.js 已安装: $nodeVersion"
    } else {
        Write-ErrorMsg "未安装 Node.js，请先安装 Node.js"
        return $false
    }
    
    # 检查配置文件
    $configPath = Join-Path $GlobalConfigDir "config.json"
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        if ($config.jira.base_url -and $config.jira.pat) {
            Write-Success "配置已设置"
        } else {
            Write-Warning "配置不完整（缺少 jira.base_url 或 jira.pat）"
        }
    } else {
        Write-Warning "未找到配置文件"
    }
    
    # 检查库文件
    $libDir = Join-Path $GlobalConfigDir "lib"
    if (Test-Path "$libDir\jira.js") {
        Write-Success "库文件已安装"
    } else {
        Write-ErrorMsg "未找到库文件"
        return $false
    }
    
    return $true
}

# 主流程
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "  Skills 安装程序" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta

# 检查 Node.js
if (-not (Test-NodeInstalled)) {
    Write-ErrorMsg "需要 Node.js 但未安装"
    Write-Host "   请从 https://nodejs.org/ 安装 Node.js" -ForegroundColor Yellow
    exit 1
}

# 第一步：展示预览并确认
$confirmed = Show-InstallPreview

if (-not $confirmed) {
    Write-Host "`n已取消安装。" -ForegroundColor Yellow
    exit 0
}

# 第二步：执行安装
Install-GlobalConfig
Install-LibFiles

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

# 第三步：验证并显示摘要
$installOk = Test-Installation

Show-InstallSummary -Target $Target -Success $installOk
