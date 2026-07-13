---
name: git-stash
description: Use when temporarily storing uncommitted changes. Triggers on keywords like "暂存更改", "git stash", "保存当前更改", "临时保存", "工作区清理".
trigger: /git-stash
---

# /git-stash

暂存或恢复工作区的更改。

## 使用方式

```
/git-stash                   # 暂存所有未提交更改
/git-stash save "描述"        # 暂存并添加描述
/git-stash list              # 查看所有暂存
/git-stash pop               # 恢复最近一次暂存并删除
/git-stash apply             # 恢复最近一次暂存（保留记录）
/git-stash drop              # 删除最近一次暂存
/git-stash clear             # 清空所有暂存
```

## What You Must Do When Invoked

### Step 1 - 解析操作类型

根据用户输入确定 stash 操作：

| 参数 | 命令 | 说明 |
|------|------|------|
| 无参数 | `git stash` | 暂存所有 |
| `save "<message>"` | `git stash save "<message>"` | 暂存并描述 |
| `list` | `git stash list` | 列出所有 |
| `pop` | `git stash pop` | 恢复并删除 |
| `apply` | `git stash apply` | 恢复（保留） |
| `drop` | `git stash drop` | 删除最近一次 |
| `clear` | `git stash clear` | 清空所有 |

### Step 2 - 验证 Git 仓库

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

如果不是 Git 仓库，提示用户切换到正确的目录。

### Step 3 - 执行 stash 操作

**暂存更改**：
```bash
# 暂存所有
git stash

# 暂存并添加描述
git stash save "描述信息"
```

**查看暂存列表**：
```bash
git stash list
```

**恢复暂存**：
```bash
# 恢复并删除（推荐）
git stash pop

# 恢复但保留记录
git stash apply
```

**删除暂存**：
```bash
# 删除最近一次
git stash drop

# 清空所有（谨慎使用）
git stash clear
```

### Step 4 - 展示结果

清晰展示操作结果：

**暂存成功时**：
- 显示暂存的描述
- 显示暂存后的状态

**恢复成功时**：
- 显示恢复的文件列表
- 显示是否成功删除暂存记录

**查看列表时**：
- 显示所有暂存的索引、描述、分支信息

## 常见用例

- **临时保存更改**：`/git-stash`
- **保存并描述用途**：`/git-stash save "修复登录bug进行中"`
- **查看所有暂存**：`/git-stash list`
- **恢复最近一次暂存**：`/git-stash pop`
- **清理工作区**：暂存后可以切换分支或拉取最新代码

## 注意事项

- `pop` 和 `apply` 的区别：`pop` 会删除暂存记录，`apply` 保留
- 如果恢复时有冲突，需要手动解决冲突
- `clear` 操作不可逆，谨慎使用
- 建议使用 `save` 添加描述，方便后续识别
