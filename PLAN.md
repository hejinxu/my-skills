# Jira Skills 实现方案

## 概述

为 Claude Code 和 OpenCode 实现 Jira 功能 skills，支持查询、操作、项目管理和 Sprint 管理。

## 目录结构

```
D:\code\workspace_skills\jira-skills\
├── package.json
├── install.ps1                  # Windows 安装脚本
├── install.sh                   # Linux/Mac 安装脚本
├── README.md
├── lib/
│   ├── config.js               # 配置读取（支持三级优先级）
│   ├── jira-client.js          # REST API 封装
│   └── utils.js                # 分页、格式化工具
└── skills/
    ├── jira-issues/
    │   └── SKILL.md
    ├── jira-projects/
    │   └── SKILL.md
    └── jira-sprint/
        └── SKILL.md
```

## 配置优先级

```
1. 环境变量 JIRA_BASE_URL, JIRA_PAT（最高优先级）
2. <项目>/.jira/config.json（项目级）
3. ~/.jira-skills/config.json（全局默认）
```

## 安装后布局

```
~/.jira-skills/
├── config.json                 # 全局默认配置
└── lib/                        # 共享脚本
    ├── config.js
    ├── jira-client.js
    └── utils.js

~/.claude/skills/ 或 ~/.config/opencode/skills/
├── jira-issues/SKILL.md
├── jira-projects/SKILL.md
└── jira-sprint/SKILL.md
```

## Skills 功能清单

### jira-issues

| 命令 | 功能 | API |
|------|------|-----|
| list <project> [--status open] | 列出 issues | GET /rest/api/2/search |
| search <jql> | JQL 搜索 | GET /rest/api/2/search |
| get <key> | issue 详情 | GET /rest/api/2/issue/{key} |
| create <project> <summary> | 创建 issue | POST /rest/api/2/issue |
| assign <key> <user> | 指派 | PUT /rest/api/2/issue/{key} |
| transition <key> <status> | 变更状态 | POST /rest/api/2/issue/{key}/transitions |
| comment <key> <text> | 添加评论 | POST /rest/api/2/issue/{key}/comment |
| assigned [--project PROJ] | 指派给我的 | JQL: assignee = currentUser() |
| mine [--project PROJ] | 我创建的 | JQL: reporter = currentUser() |

### jira-projects

| 命令 | 功能 | API |
|------|------|-----|
| list | 列出所有项目 | GET /rest/api/2/project |
| get <key> | 项目详情 | GET /rest/api/2/project/{key} |
| members <key> | 项目成员 | GET /rest/api/2/project/{key}/role |
| stats <key> | 项目统计 | JQL 聚合 |

### jira-sprint

| 命令 | 功能 | API |
|------|------|-----|
| boards | 列出看板 | GET /rest/agile/1.0/board |
| list <board> | 列出 sprints | GET /rest/agile/1.0/board/{id}/sprint |
| current <board> | 当前 sprint | 过滤 active sprint |
| issues <sprint-id> | sprint issues | GET /rest/agile/1.0/sprint/{id}/issue |

## 认证方式

Jira Server/Data Center Personal Access Token (PAT)：
```
Authorization: Bearer <token>
```

## 技术栈

- Node.js（原生 fetch，无需额外依赖）
- 无外部 npm 依赖
