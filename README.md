# My Skills

自定义 skills 集合，用于 Claude Code 和 OpenCode。

## 功能特性

### Jira Skills
- **jira-issues**：列出、搜索、创建、分配、转换和评论问题
- **jira-projects**：列出项目、查看详情、成员和统计信息
- **jira-sprint**：管理看板、冲刺和待办事项

### Code Security Check
- **code-security-check**：对代码工程进行全面的安全风险评估，识别 OWASP Top 10 安全漏洞

## 目录结构

```
gs-skills/
├── install.ps1            # Windows 安装脚本
├── install.sh             # Linux/Mac 安装脚本
├── uninstall.ps1          # Windows 卸载脚本
├── config.example.json    # 示例配置文件
├── lib/
│   ├── config.js          # 通用配置加载
│   ├── utils.js           # 通用工具函数
│   ├── jira.js            # Jira 入口文件
│   └── skills/
│       └── jira/
│           ├── client.js  # Jira API 客户端
│           └── commands.js # Jira CLI 命令
├── commands/              # OpenCode 命令模板
│   ├── jira-issues.md
│   ├── jira-projects.md
│   ├── jira-sprint.md
│   └── code-security-check.md
└── skills/                # Claude/OpenCode 技能定义
    ├── jira-issues/SKILL.md
    ├── jira-projects/SKILL.md
    ├── jira-sprint/SKILL.md
    └── code-security-check/SKILL.md
```

## 前置要求

- **Node.js** 18+
- **Jira Server/Data Center**，支持个人访问令牌（PAT）认证

## 安装

### Windows (PowerShell)

```powershell
.\install.ps1 -Target all
```

### Linux/Mac (Bash)

```bash
chmod +x install.sh
./install.sh --target all
```

### 选项

| 选项 | 说明 |
|------|------|
| `--target claude` | 仅为 Claude Code 安装 |
| `--target opencode` | 仅为 OpenCode 安装 |
| `--target all` | 为两者都安装（默认） |
| `--skip-config` | 跳过交互式配置（使用示例模板） |

## 卸载

### Windows (PowerShell)

```powershell
# 卸载所有
.\uninstall.ps1 -Target all

# 仅卸载 OpenCode，保留配置
.\uninstall.ps1 -Target opencode -KeepConfig

# 仅卸载 Claude
.\uninstall.ps1 -Target claude
```

### 卸载选项

| 选项 | 说明 |
|------|------|
| `--target claude` | 仅卸载 Claude Code 技能 |
| `--target opencode` | 仅卸载 OpenCode 技能和命令 |
| `--target all` | 卸载所有（默认） |
| `--keep-config` | 保留配置文件 `~/.config/gs-skills/config.json` |

## 配置

### 配置优先级

配置按以下顺序读取（优先级从高到低）：

1. **环境变量**：`JIRA_BASE_URL`、`JIRA_PAT`
2. **项目配置**：`<项目根目录>/.config/gs-skills/config.json`
3. **全局配置**：`~/.config/gs-skills/config.json`

### 全局配置

安装时在 `~/.config/gs-skills/config.json` 创建：

```json
{
  "jira": {
    "base_url": "https://your-jira-domain.com",
    "pat": "your_personal_access_token",
    "default_project": "PROJ"
  }
}
```

### 项目级配置

在项目根目录创建 `.config/gs-skills/config.json`：

```json
{
  "jira": {
    "base_url": "https://team-jira.company.com",
    "pat": "team_token",
    "default_project": "MY_PROJECT"
  }
}
```

这样不同的项目可以使用不同的 Jira 实例。

### 环境变量

设置以下变量可以覆盖配置文件：

```bash
export JIRA_BASE_URL=https://jira.company.com
export JIRA_PAT=your_token_here
export JIRA_DEFAULT_PROJECT=PROJ
```

## 使用方法

### 在 Claude Code 或 OpenCode 中使用

安装完成后，使用斜杠命令：

```
/jira-issues list PROJ --status open
/jira-issues assigned
/jira-issues search "assignee = currentUser() AND status != Done"
/jira-issues create PROJ "Fix login bug" --type Bug
/jira-issues transition PROJ-123 "In Progress"
/jira-issues comment PROJ-123 "Working on this now"

/jira-projects list
/jira-projects get PROJ
/jira-projects stats PROJ

/jira-sprint boards
/jira-sprint current MyBoard
/jira-sprint issues 123

# 代码安全检查
/code-security-check                    # 检查当前目录
/code-security-check /path/to/project   # 检查指定目录
```

### 直接 CLI 使用

也可以直接使用脚本：

```bash
# Windows (PowerShell)
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" list-issues --project PROJ --status open
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" search --jql "project = PROJ AND status = Open"
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" get-issue --key PROJ-123

# Linux/Mac
node "$HOME/.config/gs-skills/lib/jira.js" list-issues --project PROJ --status open
node "$HOME/.config/gs-skills/lib/jira.js" search --jql "project = PROJ AND status = Open"
node "$HOME/.config/gs-skills/lib/jira.js" get-issue --key PROJ-123
```

## 命令参考

### jira-issues

| 命令 | 说明 |
|------|------|
| `list <project>` | 列出项目中的问题 |
| `search "<jql>"` | 使用 JQL 查询搜索 |
| `get <key>` | 获取问题详情 |
| `create <project> <summary>` | 创建新问题 |
| `assign <key> <user>` | 分配问题 |
| `transition <key> <status>` | 更改问题状态 |
| `comment <key> "<text>"` | 添加评论 |
| `assigned` | 分配给我的问题 |
| `mine` | 我创建的问题 |

### jira-projects

| 命令 | 说明 |
|------|------|
| `list` | 列出所有项目 |
| `get <key>` | 获取项目详情 |
| `members <key>` | 获取项目成员 |
| `stats <key>` | 获取项目统计 |

### jira-sprint

| 命令 | 说明 |
|------|------|
| `boards` | 列出所有看板 |
| `list <board>` | 列出看板的冲刺 |
| `current <board>` | 获取当前活跃冲刺 |
| `issues <sprint-id>` | 获取冲刺中的问题 |
| `backlog <board>` | 获取待办事项 |

### code-security-check

| 命令 | 说明 |
|------|------|
| `/code-security-check` | 检查当前目录 |
| `/code-security-check <目录>` | 检查指定目录 |

**检查范围**（OWASP Top 10 2021）：
- 注入漏洞（SQL注入、XSS、命令注入）
- 文件操作安全（路径遍历、文件上传）
- 反序列化漏洞
- 服务端请求伪造（SSRF）
- 认证与授权缺陷
- 会话管理问题
- 敏感信息泄露
- 加密与传输安全
- 依赖组件漏洞
- 配置安全问题
- 错误处理与日志安全
- 业务逻辑漏洞

## 故障排除

### "Jira configuration missing"

- 检查 `~/.config/gs-skills/config.json` 是否存在且包含有效的 `jira.base_url` 和 `jira.pat`
- 或者设置 `JIRA_BASE_URL` 和 `JIRA_PAT` 环境变量

### "Jira API error 401"

- 您的 PAT 可能无效或已过期
- 在 Jira 中生成新的 PAT：个人资料 > 个人访问令牌

### "Jira API error 404"

- 检查项目键或问题键是否存在
- 验证 Jira URL 是否正确

### 技能未显示

- 安装后重启 Claude Code 或 OpenCode
- 检查技能是否已安装：
  - Claude Code：`~/.claude/skills/jira-issues/SKILL.md`
  - OpenCode：`~/.config/opencode/skills/jira-issues/SKILL.md`

### 命令不触发

- 检查命令文件格式是否正确（frontmatter 只需要 `description` 和 `agent`）
- 模板内容直接写在 frontmatter 后面，不要使用 `template` 字段
- Windows 上使用 PowerShell 语法：`$env:USERPROFILE\.config\gs-skills\lib\jira.js`
- 重启 OpenCode 使配置生效

## 开发说明

### OpenCode 命令文件格式

```markdown
---
description: 命令描述
agent: build
---

模板内容直接写在这里。

执行命令：
```
node "$env:USERPROFILE\.config\gs-skills\lib\jira.js" $ARGUMENTS
```
```

### 注意事项

1. **不要使用 `template` 字段**：模板内容直接写在 frontmatter 后面
2. **不要使用 `name` 字段**：OpenCode 从文件名推断命令名
3. **Windows 路径**：使用 `$env:USERPROFILE\.config\gs-skills\lib\jira.js`
4. **Linux/Mac 路径**：使用 `$HOME/.config/gs-skills/lib/jira.js`
5. **避免使用 `~`**：node 不支持，必须使用环境变量

## 许可证

MIT
