---
description: 查看 Git 提交历史
agent: build
---

对当前工作区执行 git log 操作，查看提交历史。

参数：$ARGUMENTS

**请加载 git-log skill 获取详细步骤。**

根据参数执行对应的 git 命令：
- 无参数：`git log --oneline -10`
- -n <count>：`git log --oneline -n <count>`
- --author <name>：`git log --author="<name>" --oneline`
- --since <date>：`git log --since="<date>" --oneline`
- -- <file>：`git log --oneline -- <file>`
- --graph：`git log --graph --oneline`

清晰展示提交历史，包括提交哈希、作者、日期、提交信息。
