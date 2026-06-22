---
name: code-security-check
description: Use when performing code security audits, vulnerability scanning, or security reviews. Triggers on keywords like "安全检查", "安全审计", "security check", "code review security", "代码安全", "漏洞扫描". Checks for hardcoded secrets, injection vulnerabilities, authentication flaws, insecure dependencies, and more.
---

# Code Security Check

对代码工程进行全面的安全风险评估，识别安全漏洞、配置问题和潜在风险，并提供具体的修复建议。

## 使用方式

```
/code-security-check                    # 检查当前目录
/code-security-check <目录路径>          # 检查指定目录
```

## 检查范围

对照 OWASP Top 10 2021 标准，按攻击面分为 4 大类、12 个检查项：

### 一、输入验证类
| 序号 | 检查类别 | OWASP 对应 |
|------|----------|------------|
| 1 | 注入漏洞检查 | A03:2021-Injection |
| 2 | 文件操作安全检查 | A01:2021-Broken Access Control |
| 3 | 反序列化漏洞检查 | A08:2021-Software and Data Integrity Failures |
| 4 | 服务端请求伪造（SSRF）检查 | A10:2021-Server-Side Request Forgery |

### 二、身份与访问控制类
| 序号 | 检查类别 | OWASP 对应 |
|------|----------|------------|
| 5 | 认证与授权缺陷检查 | A01:2021-Broken Access Control |
| 6 | 会话管理问题检查 | A07:2021-Identification and Authentication Failures |

### 三、数据安全类
| 序号 | 检查类别 | OWASP 对应 |
|------|----------|------------|
| 7 | 敏感信息泄露检查 | A02:2021-Cryptographic Failures |
| 8 | 加密与传输安全检查 | A02:2021-Cryptographic Failures |

### 四、基础设施类
| 序号 | 检查类别 | OWASP 对应 |
|------|----------|------------|
| 9 | 依赖组件漏洞检查 | A06:2021-Vulnerable and Outdated Components |
| 10 | 配置安全问题检查 | A05:2021-Security Misconfiguration |
| 11 | 错误处理与日志检查 | A09:2021-Security Logging and Monitoring Failures |
| 12 | 业务逻辑漏洞检查 | A04:2021-Insecure Design |

## What You Must Do When Invoked

### Step 1 - 确定检查目标

根据用户输入确定要检查的目录：
- 如果用户提供了目录路径，使用该目录
- 如果没有提供参数，使用当前工作目录
- 首先检查目录是否存在，是否是有效的代码工程

### Step 2 - 排除目录配置

检查时必须排除以下目录（编译输出、依赖、配置等），避免扫描第三方代码产生误报：

**必须排除的目录列表**：
```
node_modules
target
build
dist
.git
.svn
vendor
__pycache__
.venv
venv
out
.idea
.vscode
coverage
.gradle
.m2
.cache
.tmp
logs
log
```

**在所有 rg 命令中添加排除参数**：
```bash
# 全局排除参数（在每个 rg 命令后添加）
--glob '!node_modules' --glob '!target' --glob '!build' --glob '!dist' --glob '!.git' --glob '!vendor' --glob '!__pycache__' --glob '!.venv' --glob '!venv' --glob '!out' --glob '!.idea' --glob '!.vscode' --glob '!coverage' --glob '!.gradle' --glob '!.m2' --glob '!*.min.js' --glob '!*.min.css' --glob '!*.map'
```

### Step 3 - 识别项目类型

检查目标目录的项目类型，根据文件特征判断：
- **Java/Maven**：存在 `pom.xml`
- **Java/Gradle**：存在 `build.gradle`
- **JavaScript/Node.js**：存在 `package.json`
- **Python**：存在 `requirements.txt`、`setup.py`、`pyproject.toml`
- **Go**：存在 `go.mod`
- **Rust**：存在 `Cargo.toml`

### Step 4 - 执行安全检查

根据项目类型，使用合适的工具和方法进行检查。

**重要**：所有 rg 命令必须包含排除参数（见 Step 2）。

#### 4.1 敏感信息泄露检查

搜索硬编码的敏感信息：
```bash
# 搜索敏感关键词（排除编译目录）
rg -i "(password|passwd|pwd|secret|token|api_key|apikey|access_key|private_key|credential)\s*[:=]" --type-add 'code:*.{java,js,ts,py,go,rs,yml,yaml,properties,xml,json,env}' -t code --glob '!node_modules' --glob '!target' --glob '!build' --glob '!dist' --glob '!.git' --glob '!vendor' --glob '!__pycache__'

# 搜索硬编码的 IP 地址
rg "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b" --type-add 'code:*.{java,js,ts,py,go,rs,yml,yaml,properties,xml}' -t code --glob '!node_modules' --glob '!target' --glob '!build' --glob '!dist'

# 检查配置文件是否包含敏感信息
rg -i "(password|secret|token|key)\s*[:=].*['\"]" --type-add 'config:*.{yml,yaml,properties,xml,json,env}' -t config --glob '!node_modules' --glob '!target' --glob '!build'
```

#### 4.2 注入漏洞检查

```bash
# SQL 注入 - 搜索字符串拼接 SQL
rg "(SELECT|INSERT|UPDATE|DELETE).*\+.*" --type-add 'code:*.{java,js,ts,py,go}' -t code --glob '!node_modules' --glob '!target' --glob '!build' --glob '!vendor'
rg "executeQuery|executeUpdate|execute\(" --type java --glob '!target' --glob '!build'

# XSS - 搜索未转义输出
rg "innerHTML|outerHTML|document\.write|\.html\(" --type-add 'web:*.{js,ts,jsx,tsx,vue,html}' -t web --glob '!node_modules' --glob '!dist' --glob '!build'
rg "response\.write|out\.print" --type java --glob '!target' --glob '!build'

# 命令注入
rg "Runtime\.exec|ProcessBuilder|exec\(" --type java --glob '!target' --glob '!build'
rg "subprocess\.call|subprocess\.Popen|os\.system" --type py --glob '!__pycache__' --glob '!.venv'
rg "os\.exec|exec\(" --type go --glob '!vendor'
```

#### 4.3 文件操作安全检查

```bash
# 搜索文件操作
rg "new File\(|FileInputStream|FileOutputStream|Path\.of\(" --type java --glob '!target' --glob '!build'
rg "open\(|os\.path|shutil\." --type py --glob '!__pycache__' --glob '!.venv'

# 搜索文件上传
rg "MultipartFile|multipart|upload" --type-add 'code:*.{java,js,ts,py}' -t code --glob '!node_modules' --glob '!target' --glob '!build'
```

#### 4.4 依赖组件漏洞检查

```bash
# 检查 Maven 依赖（只检查根目录 pom.xml，不递归）
rg "<dependency>" -A 5 pom.xml
rg "log4j|fastjson|shiro|jackson|snakeyaml|commons-text" pom.xml

# 检查 npm 依赖（只检查根目录 package.json）
rg "log4j|fastjson|shiro|jackson|snakeyaml|commons-text" package.json

# 检查 Python 依赖（只检查根目录 requirements.txt）
rg "log4j|fastjson|shiro|jackson|snakeyaml|commons-text" requirements.txt
```

#### 4.5 认证与授权检查

```bash
# 搜索认证相关注解
rg "@PreAuthorize|@Secured|@RequiresPermissions|@RolesAllowed" --type java --glob '!target' --glob '!build'
rg "@Ignore|@PermitAll|@Anonymous" --type java --glob '!target' --glob '!build'

# 搜索 Actuator/Swagger 端点
rg "actuator|swagger|api-docs|v2/api-docs" --type-add 'config:*.{yml,yaml,properties,xml}' -t config --glob '!target' --glob '!build' --glob '!node_modules'
```

#### 4.6 配置安全检查

```bash
# 搜索默认密码
rg -i "(password|passwd)\s*[:=]\s*['\"]?(root|123456|password|admin)['\"]?" --type-add 'config:*.{yml,yaml,properties,xml,json,env}' -t config --glob '!node_modules' --glob '!target' --glob '!build'

# 搜索调试配置
rg "debug\s*[:=]\s*true|trace\s*[:=]\s*true" --type-add 'config:*.{yml,yaml,properties}' -t config --glob '!node_modules' --glob '!target' --glob '!build'

# 检查 CORS 配置
rg "Access-Control-Allow-Origin|allowedOrigins|cors" --type-add 'config:*.{yml,yaml,properties,xml,java}' -t config --glob '!node_modules' --glob '!target' --glob '!build'
```

#### 4.7 加密安全检查

```bash
# 搜索弱加密算法
rg "MessageDigest\.getInstance\(\"(MD5|SHA-1)\"\)|DigestUtils\.(md5|sha1)" --type java --glob '!target' --glob '!build'
rg "DES|3DES|RC4" --type-add 'code:*.{java,py,go}' -t code --glob '!target' --glob '!build' --glob '!vendor'

# 搜索硬编码密钥
rg "(secret|key|encrypt)\s*[:=]\s*['\"][^'\"]{8,}['\"]" --type-add 'code:*.{java,js,ts,py,go}' -t code --glob '!node_modules' --glob '!target' --glob '!build' --glob '!vendor'

# 搜索 Math.random
rg "Math\.random\(\)|new Random\(\)" --type-add 'code:*.{java,js,ts}' -t code --glob '!node_modules' --glob '!target' --glob '!build'
```

#### 4.8 反序列化检查

```bash
# Java 反序列化
rg "ObjectInputStream|readObject\(\)" --type java --glob '!target' --glob '!build'
rg "JSON\.parseObject|JSON\.parse\b" --type java --glob '!target' --glob '!build' --glob '!node_modules'

# YAML 反序列化
rg "Yaml\(\)\.load|new Yaml\(" --type java --glob '!target' --glob '!build'
```

#### 4.9 SSRF 检查

```bash
# 搜索 HTTP 客户端调用
rg "HttpURLConnection|OkHttp|RestTemplate|WebClient|HttpClient" --type-add 'code:*.{java,py,go,js,ts}' -t code --glob '!node_modules' --glob '!target' --glob '!build' --glob '!vendor'
rg "requests\.get|requests\.post|urllib" --type py --glob '!__pycache__' --glob '!.venv'
rg "http\.Get|http\.Post|http\.Do" --type go --glob '!vendor'
```

#### 4.10 日志安全检查

```bash
# 搜索日志中的敏感信息
rg "log\.(info|debug|warn|error)\(.*password|log\.(info|debug|warn|error)\(.*token" --type-add 'code:*.{java,js,ts,py,go}' -t code --glob '!node_modules' --glob '!target' --glob '!build' --glob '!vendor'
rg "System\.out\.print|console\.log" --type-add 'code:*.{java,js,ts}' -t code --glob '!node_modules' --glob '!target' --glob '!build'
```

### Step 5 - 生成检查报告

按照以下格式输出检查结果：

```markdown
# 代码安全检查报告

## 检查概要
- 检查时间：[YYYY-MM-DD HH:mm]
- 检查范围：[文件/目录]
- 项目类型：[Java/Python/Node.js 等]
- 发现问题数：[数量]
- 严重：[数量]
- 高危：[数量]
- 中危：[数量]
- 低危：[数量]

## 问题列表

### [严重] 问题标题
- **问题类型**：[类型]
- **OWASP 分类**：[A0X:2021-XXX]
- **CWE 编号**：[CWE-XXX]
- **风险等级**：严重
- **影响范围**：[描述]
- **问题位置**：[文件路径:行号]
- **问题描述**：[详细说明]
- **修复建议**：[具体修复方案]

（重复上述格式）
```

### Step 6 - 提供修复建议

对每个发现的问题，提供：
1. 问题的根本原因
2. 具体的修复方案
3. 修复后的代码示例（如适用）
4. 预防类似问题的建议

## 严重程度定义

| 等级 | 英文 | 定义 | 响应时间 |
|------|------|------|----------|
| 严重 | Critical | 可直接被利用，导致数据泄露或系统被控制 | 立即修复 |
| 高危 | High | 需要特定条件才能利用，但影响较大 | 24 小时内修复 |
| 中危 | Medium | 需要配合其他漏洞利用，或影响有限 | 一周内修复 |
| 低危 | Low | 安全最佳实践建议，不直接构成漏洞 | 择期优化 |

## 特别注意事项

1. **脱敏处理**：检查结果中如需引用敏感信息，需脱敏处理（如 `password=***`）
2. **误报处理**：如发现误报，需说明原因并从报告中移除
3. **业务理解**：结合业务逻辑评估风险，某些"问题"可能是业务需要
4. **修复可行性**：修复建议需考虑实际可操作性，避免不切实际的建议
5. **遗留风险**：如存在暂时无法修复的问题，需说明原因和后续计划

## 参考标准

- **OWASP Top 10 2021**：Web 应用安全风险 Top 10
- **CWE/SANS Top 25**：最危险的软件错误
- **GB/T 22239-2019**：信息安全技术 网络安全等级保护基本要求
- **OWASP Code Review Guide**：代码审查指南
- **OWASP ASVS**：应用安全验证标准