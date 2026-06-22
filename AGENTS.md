# AGENTS.md

## What This Repo Is

Custom skills collection for Claude Code and OpenCode, providing Jira integration (issues, projects, sprints). Pure Node.js with zero npm dependencies.

## Quick Commands

```bash
# Install for OpenCode
pwsh -File install.ps1 -Target opencode

# Install for Claude Code
pwsh -File install.ps1 -Target claude

# Install for both
pwsh -File install.ps1 -Target all

# Skip interactive config setup
pwsh -File install.ps1 -Target all -SkipConfig

# Uninstall all
pwsh -File uninstall.ps1 -Target all

# Uninstall but keep config
pwsh -File uninstall.ps1 -Target all -KeepConfig
```

No build step, no test suite, no lint config. The code runs directly via Node.js.

## Project Structure

```
lib/                    # Core Node.js code (ESM)
  jira.js              # CLI entry point
  config.js            # Config loader (3-tier priority)
  utils.js             # Formatting utilities
  skills/jira/
    client.js          # Jira REST API client
    commands.js        # CLI command implementations
commands/              # OpenCode command templates (.md)
skills/                # Claude/OpenCode skill definitions
config.example.json    # Example config file
install.ps1            # Windows installer
uninstall.ps1          # Windows uninstaller
```

## Key Gotchas

### Command File Format (OpenCode)

Files in `commands/` must follow this exact format:

```markdown
---
description: Command description
agent: build
---

Template content here.

Execution:
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" $ARGUMENTS
```

**Do NOT** use `template:` or `name:` fields in frontmatter. OpenCode infers the command name from the filename.

### Path Handling

- **Windows**: `$env:USERPROFILE\.config\gs-skills\lib\jira.js`
- **Linux/Mac**: `$HOME/.config/gs-skills/lib/jira.js`
- **Never use `~`** in node commands — Node.js doesn't expand it

### Config Priority

1. Environment variables: `JIRA_BASE_URL`, `JIRA_PAT`, `JIRA_DEFAULT_PROJECT`
2. Project config: `<project-root>/.config/gs-skills/config.json`
3. Global config: `~/.config/gs-skills/config.json`

### ESM Modules

The `lib/` directory has its own `package.json` with `"type": "module"`. All imports use ESM syntax (`import`/`export`).

### TLS

The entry point (`lib/jira.js:3`) sets `NODE_TLS_REJECT_UNAUTHORIZED = '0'` — TLS verification is disabled for self-signed certs.

## Adding New Skills

1. Create `skills/<name>/SKILL.md` with frontmatter (`name`, `description`, `trigger`)
2. Create `commands/<name>.md` with frontmatter (`description`, `agent`)
3. Add implementation in `lib/skills/<name>/`
4. Update `install.ps1` and `install.sh` to include the new skill in the install loops

## Testing Rules

**禁止修改任何现有 issue！**

测试 Jira skills 时（如修改 issue 状态、分配、评论等），必须：
1. 先创建一个专用的测试 issue
2. 所有测试操作只在这个测试 issue 上进行
3. 测试完成后可以关闭或删除该测试 issue

**原因：** 现有 issue 可能是真实业务数据，随意修改会影响团队工作。

**正确示例：**
```bash
# 1. 创建测试 issue
/jira-issues create YHJFKF2025117 "测试用issue - 请忽略" --type Task

# 2. 在测试 issue 上测试各种操作
/jira-issues transition YHJFKF2025117-XXX "In Progress"
/jira-issues assign YHJFKF2025117-XXX hejinxu
/jira-issues comment YHJFKF2025117-XXX "测试评论"
```

**错误示例：**
```bash
# ❌ 直接修改现有 issue
/jira-issues transition YHJFKF2025117-469 "In Progress"  # 不要这样做！
```

## Troubleshooting

### 命令不触发

**症状：** 执行 `/jira-issues` 后返回的是 AI 生成的内容，而不是命令执行结果。

**原因和解决：**

1. **命令文件格式错误**
   - ❌ 错误：使用 `template: |` 字段
   - ❌ 错误：使用 `name:` 字段
   - ✅ 正确：模板内容直接写在 frontmatter 后面

2. **路径语法错误**
   - ❌ 错误：`node ~/.config/gs-skills/lib/jira.js`（`~` 不被 node 支持）
   - ✅ 正确：`node "$env:USERPROFILE\.config\gs-skills\lib\jira.js"`（Windows）
   - ✅ 正确：`node "$HOME/.config/gs-skills/lib/jira.js"`（Linux/Mac）

3. **配置文件格式错误**
   - 检查 `~/.config/gs-skills/config.json` 是否为有效 JSON
   - 验证没有多余的括号或逗号

### 调试步骤

1. **先在命令行测试命令能否正常执行**
   ```bash
   node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" whoami
   ```

2. **检查配置文件是否存在且有效**
   ```powershell
   Test-Path "$env:USERPROFILE\.config\gs-skills\config.json"
   ```

3. **检查命令文件格式是否正确**
   - frontmatter 只需要 `description` 和 `agent`
   - 模板内容直接写在 frontmatter 后面

4. **重启 OpenCode 使配置生效**

### 常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `Jira configuration missing` | 配置文件不存在或为空 | 编辑 `~/.config/gs-skills/config.json` |
| `Jira API error 401` | PAT 无效或过期 | 重新生成 PAT |
| `Jira API error 404` | 项目/问题键不存在 | 检查项目键和问题键 |
| `Cannot find module` | 路径错误 | 检查路径是否正确 |
