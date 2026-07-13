---
name: git-status
description: Use when checking the current state of a Git repository. Triggers on keywords like "查看状态", "git status", "仓库状态", "当前分支", "有什么更改".
trigger: /git-status
---

# /git-status

查看当前 Git 仓库的状态。

## 使用方式

```
/git-status                  # 标准状态显示
/git-status -s               # 简洁格式
/git-status --branch         # 显示分支信息
```

## What You Must Do When Invoked

### Step 1 - 解析参数

根据用户输入确定显示格式：

| 参数 | 命令 | 说明 |
|------|------|------|
| 无参数 | `git status` | 标准格式 |
| `-s` | `git status -s` | 简洁格式 |
| `--branch` | `git status --branch` | 显示分支信息 |

### Step 2 - 验证 Git 仓库

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

如果不是 Git 仓库，提示用户切换到正确的目录。

### Step 3 - 执行 git status

```bash
git status
```

### Step 4 - 展示结果

清晰展示仓库状态：

1. **当前分支**：
   - 分支名称
   - 与远程分支的关系（领先/落后多少提交）

2. **暂存区更改**（Changes to be committed）：
   - 新增的文件
   - 修改的文件
   - 删除的文件

3. **工作区更改**（Changes not staged for commit）：
   - 修改的文件
   - 删除的文件

4. **未跟踪文件**（Untracked files）：
   - 列出未跟踪的文件

5. **汇总信息**：
   - 总共多少文件被修改
   - 多少文件待暂存
   - 多少文件未跟踪

## 常见用例

- **查看当前状态**：`/git-status`
- **快速查看摘要**：`/git-status -s`
- **查看分支信息**：`/git-status --branch`

## 注意事项

- 此操作是只读的，不会修改任何文件
- 如果有未跟踪的重要文件，建议用户考虑是否需要添加到 `.gitignore`
