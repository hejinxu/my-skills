---
description: 查看工作区中未提交的更改
agent: build
---

对当前工作区执行 git diff 操作，查看未提交的更改。

参数：$ARGUMENTS

**请加载 git-diff skill 获取详细步骤。**

根据参数执行对应的 git 命令：
- 无参数：`git diff`
- --staged：`git diff --staged`
- --stat：`git diff --stat`
- HEAD：`git diff HEAD`
- 指定文件：`git diff -- <file>`

请清晰展示差异结果，包括：
- 修改了哪些文件
- 每个文件的修改行数统计
- 具体的代码变更内容（如行数不多）
