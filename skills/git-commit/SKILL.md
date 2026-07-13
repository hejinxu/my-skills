---
name: git-commit
description: Use when committing staged changes to the local repository. Triggers on keywords like "提交更改", "git commit", "保存更改", "提交代码", "记录更改".
trigger: /git-commit
---

# /git-commit

将暂存区的更改提交到本地仓库。

## 使用方式

```
/git-commit -m "提交信息"    # 提交并添加信息
/git-commit -a -m "信息"    # 自动暂存所有已跟踪文件并提交
/git-commit                  # 交互式提交（查看状态后输入信息）
/git-commit --amend          # 修改最近一次提交
```

## What You Must Do When Invoked

### Step 1 - 解析参数

根据用户输入确定 commit 参数：

| 参数 | 命令 | 说明 |
|------|------|------|
| `-m "<message>"` | `git commit -m "<message>"` | 直接提交 |
| `-a -m "<message>"` | `git commit -a -m "<message>"` | 自动暂存并提交 |
| 无参数 | 交互式 | 先查看状态，再输入信息 |
| `--amend` | `git commit --amend` | 修改最近提交 |

### Step 2 - 验证 Git 仓库

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

如果不是 Git 仓库，提示用户切换到正确的目录。

### Step 3 - 检查暂存区状态

**提交前必须检查**：

```bash
git status
```

展示：
- 将要提交的文件列表
- 每个文件的更改摘要（新增、修改、删除）
- 如果暂存区为空，提示用户先 `git add` 添加文件

### Step 4 - 执行提交

**直接提交**（有 `-m` 参数时）：
```bash
git commit -m "<message>"
```

**自动暂存并提交**（有 `-a` 参数时）：
```bash
git commit -a -m "<message>"
```

**交互式提交**（无参数时）：
1. 展示 `git status` 结果
2. 请求用户输入提交信息
3. 执行 `git commit -m "<input>"`

**修改最近提交**：
```bash
git commit --amend -m "<new message>"
```

### Step 5 - 展示提交结果

清晰展示提交结果：

1. **提交成功**：
   - 提交哈希（短格式）
   - 提交信息
   - 修改的文件统计

2. **提交失败**：
   - 错误原因
   - 建议的解决方法

## 常见用例

- **提交已暂存的更改**：`/git-commit -m "feat: 添加用户登录功能"`
- **快速提交所有已跟踪文件的更改**：`/git-commit -a -m "fix: 修复样式问题"`
- **修改上次提交信息**：`/git-commit --amend -m "feat: 添加用户登录功能（修正）"`
- **交互式提交**：`/git-commit`

## 注意事项

- 提交前确保暂存区包含所有需要提交的更改
- 提交信息应清晰描述更改内容
- `--amend` 会修改提交历史，如果已经推送需要 force push
- `git commit -a` 只暂存已跟踪文件的更改，新文件需要先 `git add`
