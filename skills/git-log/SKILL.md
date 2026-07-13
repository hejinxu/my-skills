---
name: git-log
description: Use when viewing commit history. Triggers on keywords like "查看提交历史", "git log", "提交记录", "谁改了什么", "最近的提交".
trigger: /git-log
---

# /git-log

查看 Git 提交历史。

## 使用方式

```
/git-log                     # 显示最近 10 条提交
/git-log -n 20               # 显示最近 20 条提交
/git-log --author "张三"      # 按作者筛选
/git-log --since "2024-01-01" # 按日期筛选
/git-log -- src/main.js      # 查看指定文件的历史
/git-log --oneline           # 单行格式
/git-log --graph             # 图形化显示分支
```

## What You Must Do When Invoked

### Step 1 - 解析参数

根据用户输入确定 log 参数：

| 参数 | 命令 | 说明 |
|------|------|------|
| 无参数 | `git log --oneline -10` | 最近 10 条，单行 |
| `-n <count>` | `git log --oneline -n <count>` | 指定数量 |
| `--author <name>` | `git log --author="<name>" --oneline` | 按作者 |
| `--since <date>` | `git log --since="<date>" --oneline` | 按日期 |
| `-- <file>` | `git log --oneline -- <file>` | 指定文件 |
| `--graph` | `git log --graph --oneline` | 图形化 |

### Step 2 - 验证 Git 仓库

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

如果不是 Git 仓库，提示用户切换到正确的目录。

### Step 3 - 执行 git log

根据参数执行对应的 git 命令：

```bash
# 默认：最近 10 条，单行格式
git log --oneline -10

# 指定数量
git log --oneline -n 20

# 按作者筛选
git log --author="张三" --oneline

# 按日期筛选
git log --since="2024-01-01" --oneline

# 查看指定文件的历史
git log --oneline -- <file>

# 图形化显示
git log --graph --oneline
```

### Step 4 - 展示结果

清晰展示提交历史：

1. **单行格式**（默认）：
   ```
   abc1234 feat: 添加用户登录功能
   def5678 fix: 修复密码验证问题
   ```

2. **详细格式**（当用户需要时）：
   - 提交哈希
   - 作者
   - 日期
   - 提交信息

3. **图形化格式**（使用 `--graph` 时）：
   - 清晰展示分支结构

## 常见用例

- **查看最近做了什么**：`/git-log`
- **查看某人的提交**：`/git-log --author "张三"`
- **查看某个文件的修改历史**：`/git-log -- src/main.js`
- **查看本周的提交**：`/git-log --since "7 days ago"`
- **查看分支结构**：`/git-log --graph`

## 注意事项

- 此操作是只读的，不会修改任何文件
- 如果输出过长，建议使用 `-n` 限制显示数量
- 对于二进制文件，无法显示具体内容
