---
name: git-restore
description: Use when discarding uncommitted changes in the working directory. Triggers on keywords like "还原更改", "撤销修改", "git restore", "git checkout", "丢弃更改", "恢复原状", "放弃修改".
trigger: /git-restore
---

# /git-restore

还原工作区中未提交的更改（不可逆操作）。

## 使用方式

```
/git-restore                 # 还原所有未提交的更改
/git-restore all             # 还原所有未提交的更改
/git-restore <file>          # 还原指定文件的更改
```

## What You Must Do When Invoked

### Step 1 - 解析参数

根据用户输入确定还原范围：

| 参数 | 说明 |
|------|------|
| 无参数 / `all` | 还原所有未提交的更改 |
| `<file>` | 还原指定文件的更改 |

### Step 2 - 验证 Git 仓库

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

如果不是 Git 仓库，提示用户切换到正确的目录。

### Step 3 - 展示将被还原的内容

**必须在执行还原前展示将被还原的内容**：

```bash
# 查看工作区的更改
git status

# 或查看具体文件的更改
git diff -- <file>
```

展示内容：
- 将被还原的文件列表
- 每个文件的更改摘要（增删行数）

### Step 4 - 请求用户确认

**这是关键步骤**！必须请求用户确认：

```
⚠️ 警告：此操作不可逆！以下更改将被丢弃：
- file1.js (+10, -5)
- file2.ts (+3, -12)

确认要还原这些更改吗？
```

等待用户明确确认后才能执行。如果用户取消，终止操作。

### Step 5 - 执行还原

用户确认后，执行还原命令：

**还原工作区所有文件**（Git 2.23+ 推荐方式）：
```bash
git restore .
```

**还原指定文件**：
```bash
git restore <file>
```

**取消所有暂存**：
```bash
git reset HEAD -- .
```

**取消指定文件暂存**：
```bash
git reset HEAD -- <file>
```

### Step 6 - 确认结果

执行 `git status` 确认还原成功，并向用户报告结果。

## 常见用例

- **放弃所有更改，重新开始**：`/git-restore`
- **只还原某个文件**：`/git-restore src/config.js`
- **取消暂存但保留更改**：需要手动执行 `git reset HEAD`

## 注意事项

- **不可逆**：此操作会永久丢弃未提交的更改
- **只影响未提交的更改**：已提交的历史不受影响
- **安全建议**：重要更改先用 `git stash` 暂存
- **暂存区更改**：如果文件已暂存，需要先 `git reset HEAD -- <file>` 取消暂存，再还原
