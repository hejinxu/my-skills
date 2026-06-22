---
description: 执行代码安全检查，识别代码中的安全漏洞和风险
agent: build
---

对代码工程执行全面的安全检查，识别安全漏洞并提供修复建议。

**目标目录**：$ARGUMENTS（如未指定则使用当前工作目录）

请加载 code-security-check skill 获取详细的检查步骤和标准，然后按照以下步骤执行：

1. 确定检查目标目录
2. 识别项目类型
3. 执行 12 项安全检查（注入、文件操作、反序列化、SSRF、认证授权、会话管理、敏感信息泄露、加密传输、依赖组件、配置安全、日志安全、业务逻辑）
4. 生成标准化安全检查报告
5. **保存报告文件**到 `<项目根目录>/docs/代码安全检查结果/code-security-report-YYYYMMDD-HHmmss.md`

**报告保存路径**：
```
<项目根目录>/docs/代码安全检查结果/code-security-report-YYYYMMDD-HHmmss.md
```

**保存命令**（Windows PowerShell）：
```powershell
# 创建目录
$reportDir = Join-Path $TargetDir "docs\代码安全检查结果"
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

# 生成报告文件名
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFile = Join-Path $reportDir "code-security-report-$timestamp.md"

# 保存报告
$reportContent | Set-Content -Path $reportFile -Encoding UTF8
Write-Host "检查报告已保存到: $reportFile" -ForegroundColor Green
```

**输出格式**：
```markdown
# 代码安全检查报告

## 检查概要
- 检查时间：[YYYY-MM-DD HH:mm:ss]
- 检查范围：[目录]
- 项目类型：[Java/Python/Node.js 等]
- 发现问题数：[数量]
- 严重：[数量]
- 高危：[数量]
- 中危：[数量]
- 低危：[数量]

## 问题列表

### [严重程度] 问题标题
- **问题类型**：[类型]
- **OWASP 分类**：[A0X:2021-XXX]
- **CWE 编号**：[CWE-XXX]
- **风险等级**：[严重/高危/中危/低危]
- **问题位置**：[文件:行号]
- **问题描述**：[描述]
- **修复建议**：[建议]
```