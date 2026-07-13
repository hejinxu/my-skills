---
name: git-blame
description: Use when viewing line-by-line modification history of a file. Triggers on keywords like "查看修改历史", "git blame", "谁改了这行", "这行代码谁写的", "逐行追溯".
trigger: /git-blame
---

# /git-blame

查看文件的逐行修改历史（谁在什么时候改了哪一行）。

## 使用方式

```
/git-blame <file>            # 查看文件的完整 blame
/git-blame <file> -L 10,20   # 查看第 10-20 行
/git-blame <file> --since "2024-01-01"  # 只显示指定日期后的修改
```

## What You Must Do When Invoked

### Step 1 - 解析参数

根据用户输入确定 blame 参数：

| 参数 | 命令 | 说明 |
|------|------|------|
| `<file>` | `git blame <file>` | 完整 blame |
| `<file> -L <start>,<end>` | `git blame -L <start>,<end> <file>` | 指定行范围 |
| `<file> --since <date>` | `git blame --since="<date>" <file>` | 按日期筛选 |

**注意**：必须提供文件路径参数。

### Step 2 - 验证 Git 仓库和文件

首先确认当前目录是 Git 仓库：
```bash
git rev-parse --is-inside-work-tree
```

然后确认文件存在：
```bash
test -f <file> && echo "文件存在" || echo "文件不存在"
```

### Step 3 - 执行 git blame

根据参数执行对应的 git 命令：

```bash
# 完整 blame
git blame <file>

# 指定行范围
git blame -L <start>,<end> <file>

# 按日期筛选
git blame --since="<date>" <file>
```

### Step 4 - 展示结果

清晰展示 blame 结果：

1. **逐行信息**：
   ```
   abc1234 (张三 2024-01-15)  const user = getUser();
   def5678 (李四 2024-02-20)  return user.name;
   ```

2. **汇总统计**：
   - 每个作者修改了多少行
   - 最后修改时间

3. **指定行范围时**：
   - 显示指定行的 blame 信息
   - 标注行号

## 常见用例

- **查看文件是谁写的**：`/git-blame src/main.js`
- **查看某行代码的来源**：`/git-blame src/main.js -L 10,10`
- **查看最近谁改过这个文件**：`/git-blame src/main.js --since "7 days ago"`

## 注意事项

- 此操作是只读的，不会修改任何文件
- 必须提供文件路径参数
- 对于二进制文件，无法显示 blame 信息
- 合并提交可能显示为 `^abc1234`（表示合并点）
