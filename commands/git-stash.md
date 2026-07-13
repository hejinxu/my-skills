---
description: 暂存或恢复工作区的更改
agent: build
---

对当前工作区执行 git stash 操作，暂存或恢复更改。

参数：$ARGUMENTS

**请加载 git-stash skill 获取详细步骤。**

根据参数执行对应操作：
- 无参数：`git stash`（暂存所有）
- save "<message>"：`git stash save "<message>"`
- list：`git stash list`
- pop：`git stash pop`
- apply：`git stash apply`
- drop：`git stash drop`
- clear：`git stash clear`

清晰展示操作结果：
- 暂存成功时显示描述
- 恢复成功时显示恢复的文件列表
- 查看列表时显示所有暂存信息
