---
name: git-diff
description: Use when viewing uncommitted changes in the working directory. Triggers on keywords like "查看修改", "对比差异", "git diff", "看看改了什么", "有哪些更改", "查看更改".
trigger: /git-diff
---

# /git-diff

查看工作区中未提交的更改。

## 使用方式

```
/git-diff                    # 显示所有未暂存的更改
/git-diff --staged           # 显示已暂存的更改
/git-diff <file>             # 显示指定文件的差异
/git-diff --stat             # 仅显示统计信息
/git-diff HEAD               # 显示工作区与 HEAD 的差异（包含暂存区）
```

## What You Must Do When Invoked

### Step 1 - 解析参数

根据用户输入确定 diff 模式：

| 参数 | 命令 | 说明 |
|------|------|------|
| 无参数 | `git diff` | 工作区 vs 暂存区 |
| `--staged` | `git diff --staged` | 暂存区 vs HEAD |
| `--stat` | `git diff --stat` | 仅统计信息 |
| `HEAD` | `git diff HEAD` | 工作区 vs HEAD |
| `<file>` | `git diff -- <file>` | 指定文件 |
| `--staged <file>` | `git diff --staged -- <file>` | 指定文件的已暂存更改 |

### Step 2 - 验证 Git 仓库

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

如果不是 Git 仓库，提示用户切换到正确的目录。

### Step 3 - 执行 git diff

根据参数执行对应的 git 命令：

```bash
# 无参数 - 显示所有未暂存的更改
git diff

# 显示已暂存的更改
git diff --staged

# 显示统计信息
git diff --stat

# 显示工作区与 HEAD 的差异
git diff HEAD

# 显示指定文件的差异
git diff -- <file>
```

### Step 4 - 展示结果

清晰展示 diff 结果：

1. **统计视图**（使用 `--stat` 或结果较长时）：
   - 列出修改的文件
   - 每个文件的增删行数

2. **详细视图**（行数不多时）：
   - 按文件分组展示
   - 突出显示新增（绿色）和删除（红色）的行
   - 标注行号

3. **无更改时**：
   - 如果没有未提交的更改，明确告知用户

## 常见用例

- **查看今天改了什么**：`/git-diff`
- **查看某个文件的更改**：`/git-diff src/main.js`
- **查看暂存区内容**：`/git-diff --staged`
- **快速查看哪些文件被修改**：`/git-diff --stat`

## 注意事项

- 此操作是只读的，不会修改任何文件
- 如果输出过长，建议使用 `--stat` 先查看统计，再用 `-- <file>` 查看具体文件
