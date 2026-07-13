---
description: 查看文件的逐行修改历史
agent: build
---

对指定文件执行 git blame 操作，查看逐行修改历史。

参数：$ARGUMENTS

**请加载 git-blame skill 获取详细步骤。**

**必须提供文件路径**。执行 `git blame` 并展示：
- 每行代码的最后修改者
- 修改时间
- 提交哈希

支持参数：
- `<file>`：完整 blame
- `<file> -L <start>,<end>`：指定行范围
- `<file> --since <date>`：只显示指定日期后的修改
