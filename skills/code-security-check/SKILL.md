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

| 类别 | 序号 | 检查类别 | OWASP 对应 |
|------|------|----------|------------|
| 输入验证类 | 1 | 注入漏洞检查 | A03:2021-Injection |
| 输入验证类 | 2 | 文件操作安全检查 | A01:2021-Broken Access Control |
| 输入验证类 | 3 | 反序列化漏洞检查 | A08:2021-Software and Data Integrity Failures |
| 输入验证类 | 4 | 服务端请求伪造（SSRF）检查 | A10:2021-Server-Side Request Forgery |
| 身份与访问控制类 | 5 | 认证与授权缺陷检查 | A01:2021-Broken Access Control |
| 身份与访问控制类 | 6 | 会话管理问题检查 | A07:2021-Identification and Authentication Failures |
| 数据安全类 | 7 | 敏感信息泄露检查 | A02:2021-Cryptographic Failures |
| 数据安全类 | 8 | 加密与传输安全检查 | A02:2021-Cryptographic Failures |
| 基础设施类 | 9 | 依赖组件漏洞检查 | A06:2021-Vulnerable and Outdated Components |
| 基础设施类 | 10 | 配置安全问题检查 | A05:2021-Security Misconfiguration |
| 基础设施类 | 11 | 错误处理与日志检查 | A09:2021-Security Logging and Monitoring Failures |
| 基础设施类 | 12 | 业务逻辑漏洞检查 | A04:2021-Insecure Design |

---

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

**Windows PowerShell 排除目录**：
```powershell
# 排除目录列表
$ExcludeDirs = @("node_modules", "target", "build", "dist", ".git", "vendor", "__pycache__", ".venv", "venv", "out", ".idea", ".vscode", "coverage", ".gradle", ".m2")

# 搜索文件时排除这些目录
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go,*.yml,*.yaml,*.properties,*.xml,*.json,*.env -ExcludeDir $ExcludeDirs | Select-String -Pattern "pattern"
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

检查完成后，执行 Step 5（生成报告）和 Step 6（提供修复建议）。

---

#### 一、输入验证类

##### 1.1 注入漏洞检查

**OWASP 对应**：A03:2021-Injection

**检查目标**：识别 SQL 注入、XSS、命令注入、LDAP 注入等注入类漏洞

**检查要点**：
- SQL 查询是否使用参数化（`PreparedStatement`）
- 用户输入是否进行过滤和转义
- 是否存在拼接 SQL 语句
- 是否存在命令拼接执行（`Runtime.exec()`、`ProcessBuilder`）
- 输出到页面的内容是否转义（XSS）
- 是否存在 EL 表达式注入
- 是否存在 XML 外部实体注入（XXE）

**常见问题**：
- 字符串拼接 SQL 查询（`"SELECT * FROM user WHERE id=" + userId`）
- 直接使用 `eval()`、`exec()` 执行用户输入
- 未转义直接输出到 HTML
- 使用正则过滤而非参数化
- XML 解析未禁用外部实体
- 模板引擎未对输入进行转义

**检查方法**（Windows PowerShell）：
```powershell
# SQL 注入 - 搜索字符串拼接 SQL
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "(SELECT|INSERT|UPDATE|DELETE).*\+"
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "executeQuery|executeUpdate|execute\("

# XSS - 搜索未转义输出
Get-ChildItem -Path . -Recurse -Include *.js,*.ts,*.jsx,*.tsx,*.vue,*.html -ExcludeDir $ExcludeDirs | Select-String -Pattern "innerHTML|outerHTML|document\.write|\.html\("
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "response\.write|out\.print"

# 命令注入
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "Runtime\.exec|ProcessBuilder|exec\("
Get-ChildItem -Path . -Recurse -Include *.py -ExcludeDir $ExcludeDirs | Select-String -Pattern "subprocess\.call|subprocess\.Popen|os\.system"
Get-ChildItem -Path . -Recurse -Include *.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "os\.exec|exec\("
```

**修复建议**：
- 使用参数化查询或 ORM 框架（MyBatis 使用 `#{}`）
- 禁止使用 `eval()`、`exec()` 执行用户输入
- 输出到 HTML 时进行编码转义
- XML 解析禁用外部实体（`setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)`）
- 使用白名单过滤用户输入

**CWE 参考**：CWE-89（SQL注入）、CWE-79（XSS）、CWE-78（命令注入）、CWE-611（XXE）

---

##### 1.2 文件操作安全检查

**OWASP 对应**：A01:2021-Broken Access Control

**检查目标**：识别路径遍历、文件上传、任意文件读写等漏洞

**检查要点**：
- 文件路径是否可被用户控制
- 是否存在路径遍历（`../`、`..\\`）
- 文件上传是否校验文件类型
- 文件上传是否限制文件大小
- 上传文件是否存储在 Web 可访问目录
- 是否允许上传可执行文件（`.jsp`、`.php`、`.exe`）
- 临时文件是否及时清理

**常见问题**：
- 直接使用用户输入拼接文件路径
- 仅通过前端校验文件类型
- 上传文件存储在 Web 根目录
- 未限制上传文件大小（DoS 风险）
- 文件名未做处理（特殊字符、超长文件名）

**检查方法**（Windows PowerShell）：
```powershell
# 搜索文件操作
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "new File\(|FileInputStream|FileOutputStream|Path\.of\("
Get-ChildItem -Path . -Recurse -Include *.py -ExcludeDir $ExcludeDirs | Select-String -Pattern "open\(|os\.path|shutil\."

# 搜索文件上传
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py -ExcludeDir $ExcludeDirs | Select-String -Pattern "MultipartFile|multipart|upload"
```

**修复建议**：
- 文件路径使用白名单限制，禁止用户输入直接拼接
- 使用 `file.getCanonicalPath()` 检查路径是否在允许范围内
- 文件上传校验扩展名（白名单）+ 文件头（Magic Number）
- 上传文件存储在非 Web 可访问目录
- 设置上传文件大小限制
- 上传文件重命名（使用 UUID）

**CWE 参考**：CWE-22（路径遍历）、CWE-434（文件上传）、CWE-23（相对路径遍历）

---

##### 1.3 反序列化漏洞检查

**OWASP 对应**：A08:2021-Software and Data Integrity Failures

**检查目标**：识别不安全的反序列化操作

**检查要点**：
- 是否使用原生 Java 反序列化（`ObjectInputStream`）
- 是否使用 Fastjson 等已知存在漏洞的库
- 反序列化数据是否来自不可信来源
- 是否有反序列化白名单过滤
- YAML 解析是否安全
- 是否使用 `readObject()` 方法

**常见问题**：
- 直接反序列化用户输入
- Fastjson 未开启安全模式
- YAML 解析未禁用反序列化
- 使用 `ObjectInputStream` 而未做类过滤

**检查方法**（Windows PowerShell）：
```powershell
# Java 反序列化
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "ObjectInputStream|readObject\(\)"
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "JSON\.parseObject|JSON\.parse"

# YAML 反序列化
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "Yaml\(\)\.load|new Yaml\("
```

**修复建议**：
- 避免使用原生 Java 反序列化
- Fastjson 升级到最新版本并开启安全模式
- YAML 解析使用 `Yaml().load()` 替代 `Yaml().loadAs()`
- 实现反序列化白名单过滤
- 考虑使用 JSON 等安全格式替代

**CWE 参考**：CWE-502（反序列化）、CWE-502（不可信数据反序列化）

---

##### 1.4 服务端请求伪造（SSRF）检查

**OWASP 对应**：A10:2021-Server-Side Request Forgery

**检查目标**：识别可被利用发起内网请求的漏洞

**检查要点**：
- 是否有从用户输入获取 URL 的功能
- 获取到的 URL 是否直接用于发起请求
- 是否有限制请求目标（禁止内网 IP）
- 是否有 DNS 重绑定防护
- 是否支持协议限制（只允许 HTTP/HTTPS）

**常见问题**：
- 图片抓取功能未限制目标地址
- Webhook 功能未校验目标 URL
- 导入 URL 功能未做网络隔离
- 未禁止访问内网服务（`127.0.0.1`、`10.x.x.x`、`192.168.x.x`）

**检查方法**（Windows PowerShell）：
```powershell
# 搜索 HTTP 客户端调用
Get-ChildItem -Path . -Recurse -Include *.java,*.py,*.go,*.js,*.ts -ExcludeDir $ExcludeDirs | Select-String -Pattern "HttpURLConnection|OkHttp|RestTemplate|WebClient|HttpClient"
Get-ChildItem -Path . -Recurse -Include *.py -ExcludeDir $ExcludeDirs | Select-String -Pattern "requests\.get|requests\.post|urllib"
Get-ChildItem -Path . -Recurse -Include *.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "http\.Get|http\.Post|http\.Do"
```

**修复建议**：
- URL 白名单限制可访问的域名/IP
- 禁止访问内网 IP 段
- 使用 DNS 解析后的 IP 进行校验（防止 DNS 重绑定）
- 网络层面实施隔离（应用服务器与内网服务隔离）
- 限制协议类型（只允许 HTTP/HTTPS）

**CWE 参考**：CWE-918（SSRF）

---

#### 二、身份与访问控制类

##### 2.1 认证与授权缺陷检查

**OWASP 对应**：A01:2021-Broken Access Control

**检查目标**：识别接口鉴权缺失、越权访问风险

**检查要点**：
- 对外接口是否需要认证
- 认证逻辑是否可绕过
- 权限校验是否完整
- 是否存在水平越权（同权限不同用户互相访问数据）
- 是否存在垂直越权（低权限用户操作高权限功能）
- 接口参数是否可被篡改（如修改 userId 查询他人数据）

**常见问题**：
- 接口未添加认证注解（如 `@PreAuthorize`、`@Secured`、`@RequiresPermissions`）
- 认证逻辑写在业务层而非控制层，部分入口未覆盖
- 直接使用请求参数中的用户 ID 而非从 Token/Session 中获取
- 权限校验不完整，只校验了功能权限未校验数据权限
- 管理后台接口未做角色校验

**检查方法**（Windows PowerShell）：
```powershell
# 搜索认证相关注解
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "@PreAuthorize|@Secured|@RequiresPermissions|@RolesAllowed"
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "@Ignore|@PermitAll|@Anonymous"

# 搜索 Actuator/Swagger 端点
Get-ChildItem -Path . -Recurse -Include *.yml,*.yaml,*.properties,*.xml -ExcludeDir $ExcludeDirs | Select-String -Pattern "actuator|swagger|api-docs|v2/api-docs"
```

**修复建议**：
- 所有对外接口必须添加认证注解
- 用户身份从 Token/Session 中获取，而非请求参数
- 实现数据权限控制，确保用户只能访问自己的数据
- 使用 RBAC 模型统一管理权限

**CWE 参考**：CWE-862（未授权访问）、CWE-863（错误授权）、CWE-639（越权访问）

---

##### 2.2 会话管理问题检查

**OWASP 对应**：A07:2021-Identification and Authentication Failures

**检查目标**：识别 Token 处理、会话管理缺陷

**检查要点**：
- Token 生成算法是否安全（避免使用 `Math.random()`、`Random`）
- Token 有效期设置是否合理（建议 30 分钟 - 2 小时）
- Token 存储方式是否安全（避免 LocalStorage）
- 会话固定风险（登录后是否重新生成 Session）
- 会话超时处理
- 密码重置 Token 是否一次性使用

**常见问题**：
- 使用 `Math.random()`、`new Random()` 生成 Token
- Token 永不过期或有效期过长
- Token 存储在 LocalStorage（可被 XSS 窃取）
- 登录后未重新生成 Session ID
- 密码重置链接可重复使用
- 未做会话注销逻辑

**检查方法**（Windows PowerShell）：
```powershell
# 搜索 Token 生成逻辑
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "Math\.random\(\)|new Random\(\)|SecureRandom|UUID\.randomUUID"
Get-ChildItem -Path . -Recurse -Include *.js,*.ts -ExcludeDir $ExcludeDirs | Select-String -Pattern "Math\.random\(\)|crypto\.randomBytes|uuid\.v4"

# 搜索 Token 存储
Get-ChildItem -Path . -Recurse -Include *.js,*.ts,*.html,*.vue -ExcludeDir $ExcludeDirs | Select-String -Pattern "localStorage|sessionStorage|\.setCookie|HttpOnly|Secure|SameSite"
```

**修复建议**：
- 使用 `SecureRandom` 或 UUID 生成 Token
- Token 设置合理有效期（推荐 JWT + Refresh Token 模式）
- 使用 Cookie 存储 Token，设置 `HttpOnly`、`Secure`、`SameSite` 属性
- 登录成功后重新生成 Session ID
- 密码重置 Token 一次性使用

**CWE 参考**：CWE-330（不安全随机数）、CWE-613（会话过期不足）

---

#### 三、数据安全类

##### 3.1 敏感信息泄露检查

**OWASP 对应**：A02:2021-Cryptographic Failures

**检查目标**：识别代码中硬编码的敏感信息及不当的敏感数据处理

**检查要点**：
- 数据库连接字符串（包含用户名密码）
- API 密钥、访问令牌、私钥、证书
- 服务器 IP 地址、内部域名
- 测试账号、默认密码
- 日志中记录的敏感信息
- 硬编码的加密密钥、盐值
- 第三方服务凭据（微信、支付宝、短信等）
- 配置文件是否被提交到代码仓库

**常见模式**：
```
敏感关键词：password, passwd, pwd, secret, token, api_key, apikey, access_key, 
private_key, credential, encrypt_key, salt, iv, connection_string, jdbc, datasource
配置文件：.properties, .yml, .yaml, .json, .env, .ini, .xml
```

**检查方法**（Windows PowerShell）：
```powershell
# 搜索敏感关键词（排除编译目录）
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go,*.rs,*.yml,*.yaml,*.properties,*.xml,*.json,*.env -ExcludeDir $ExcludeDirs | Select-String -Pattern "(password|passwd|pwd|secret|token|api_key|apikey|access_key|private_key|credential)\s*[:=]" -CaseSensitive:$false

# 搜索硬编码的 IP 地址
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go,*.rs,*.yml,*.yaml,*.properties,*.xml -ExcludeDir $ExcludeDirs | Select-String -Pattern "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"

# 检查配置文件是否包含敏感信息
Get-ChildItem -Path . -Recurse -Include *.yml,*.yaml,*.properties,*.xml,*.json,*.env -ExcludeDir $ExcludeDirs | Select-String -Pattern "(password|secret|token|key)\s*[:=].*['""]" -CaseSensitive:$false
```

**修复建议**：
- 敏感信息使用环境变量或配置中心管理
- 配置文件中的密码使用 Jasypt 等工具加密
- 日志输出时对敏感字段脱敏（如 `password=***`）
- 使用密钥管理服务（如 Vault、AWS Secrets Manager）
- 将配置文件加入 `.gitignore`

**CWE 参考**：CWE-798（硬编码凭据）、CWE-312（明文存储敏感信息）、CWE-532（日志信息泄露）

---

##### 3.2 加密与传输安全检查

**OWASP 对应**：A02:2021-Cryptographic Failures

**检查目标**：识别弱加密算法、明文传输

**检查要点**：
- 是否使用弱加密算法（MD5、SHA1 用于密码）
- 是否使用 DES、3DES 等过时算法
- 密码是否加盐存储
- 敏感数据是否明文传输
- HTTPS 配置是否正确（TLS 版本、证书）
- 随机数生成是否使用安全算法

**常见问题**：
- 密码使用 MD5 加密（无盐值）
- 使用 DES 等弱加密算法
- 使用 `Math.random()` 生成密钥
- HTTP 明文传输敏感数据
- 使用 TLS 1.0/1.1

**检查方法**（Windows PowerShell）：
```powershell
# 搜索弱加密算法
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern 'MessageDigest\.getInstance\("(MD5|SHA-1)"\)|DigestUtils\.(md5|sha1)'
Get-ChildItem -Path . -Recurse -Include *.java,*.py,*.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "DES|3DES|RC4"

# 搜索硬编码密钥
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "(secret|key|encrypt)\s*[:=]\s*['""][^'""]{8,}['""]"

# 搜索 Math.random
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts -ExcludeDir $ExcludeDirs | Select-String -Pattern "Math\.random\(\)|new Random\(\)"
```

**修复建议**：
- 密码使用 BCrypt、SCrypt、Argon2 存储
- 使用 AES-256-GCM 等安全加密算法
- 使用 `SecureRandom` 生成随机数
- 敏感数据传输使用 HTTPS
- 使用 TLS 1.2+

**CWE 参考**：CWE-327（弱加密算法）、CWE-328（弱哈希）、CWE-326（加密强度不足）

---

#### 四、基础设施类

##### 4.1 依赖组件漏洞检查

**OWASP 对应**：A06:2021-Vulnerable and Outdated Components

**检查目标**：识别使用已知高危漏洞的第三方组件

**检查要点**：
- 检查依赖版本是否为已知漏洞版本

| 组件 | 漏洞版本 | 漏洞类型 |
|------|----------|----------|
| Log4j 2.x | 2.0.0 - 2.14.1 | JNDI 注入（CVE-2021-44228） |
| Spring Framework | < 5.3.18 | RCE（CVE-2022-22965） |
| Fastjson | < 1.2.83 | 反序列化 RCE |
| Apache Shiro | < 1.10.0 | 认证绕过（CVE-2022-32532） |
| Jackson | < 2.13.4 | 反序列化漏洞 |
| Apache Commons Text | < 1.10.0 | 注入（CVE-2022-42889） |
| SnakeYAML | < 2.0 | 反序列化（CVE-2022-1471） |
| Tomcat | < 9.0.68 | 多个漏洞 |

**检查方法**（Windows PowerShell）：
```powershell
# 检查 Maven 依赖（只检查根目录 pom.xml，不递归）
Get-Content pom.xml | Select-String -Pattern "<dependency>" -Context 0,5
Get-Content pom.xml | Select-String -Pattern "log4j|fastjson|shiro|jackson|snakeyaml|commons-text"

# 检查 npm 依赖（只检查根目录 package.json）
Get-Content package.json | Select-String -Pattern "log4j|fastjson|shiro|jackson|snakeyaml|commons-text"

# 检查 Python 依赖（只检查根目录 requirements.txt）
Get-Content requirements.txt | Select-String -Pattern "log4j|fastjson|shiro|jackson|snakeyaml|commons-text"
```

**修复建议**：
- 升级到安全版本
- 使用 BOM（Bill of Materials）统一管理依赖版本
- 定期执行依赖扫描
- 移除不再使用的依赖

**CWE 参考**：CWE-1035（易受攻击的第三方组件）

---

##### 4.2 配置安全问题检查

**OWASP 对应**：A05:2021-Security Misconfiguration

**检查目标**：识别敏感配置暴露、默认配置、不必要的功能启用

**检查要点**：
- 配置文件是否包含明文密码
- 是否使用默认密码（数据库、Redis、MQ、管理后台）
- 是否启用了不必要的调试功能
- 是否暴露了服务器版本信息
- CORS 配置是否过于宽松
- 是否有不必要的端口开放
- 是否有未授权访问的端点（如 Actuator、Swagger）

**常见问题**：
- 数据库密码明文存储在配置文件
- Redis、MySQL 等使用默认密码
- 调试模式未关闭（`debug=true`）
- 服务器返回版本信息（`Server: Apache/2.4.x`）
- CORS 配置为 `allow-all`（`Access-Control-Allow-Origin: *`）
- 生产环境暴露 Swagger 文档、Actuator 端点

**检查方法**（Windows PowerShell）：
```powershell
# 搜索默认密码
Get-ChildItem -Path . -Recurse -Include *.yml,*.yaml,*.properties,*.xml,*.json,*.env -ExcludeDir $ExcludeDirs | Select-String -Pattern "(password|passwd)\s*[:=]\s*(root|123456|password|admin)" -CaseSensitive:$false

# 搜索调试配置
Get-ChildItem -Path . -Recurse -Include *.yml,*.yaml,*.properties -ExcludeDir $ExcludeDirs | Select-String -Pattern "debug\s*[:=]\s*true|trace\s*[:=]\s*true"

# 检查 CORS 配置
Get-ChildItem -Path . -Recurse -Include *.yml,*.yaml,*.properties,*.xml,*.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "Access-Control-Allow-Origin|allowedOrigins|cors"
```

**修复建议**：
- 敏感配置使用环境变量或配置中心
- 修改所有默认密码
- 生产环境关闭调试模式
- 配置 HTTP 响应头隐藏版本信息
- CORS 配置使用白名单
- 生产环境关闭 Swagger、Actuator 等调试端点

**CWE 参考**：CWE-16（配置问题）、CWE-200（信息暴露）

---

##### 4.3 错误处理与日志检查

**OWASP 对应**：A09:2021-Security Logging and Monitoring Failures

**检查目标**：识别异常处理不当、敏感操作未记录

**检查要点**：
- 异常信息是否直接返回给前端
- 错误页面是否暴露技术细节
- 敏感操作是否记录审计日志
- 日志级别是否正确（生产环境避免 DEBUG）
- 日志文件是否有访问控制
- 是否有统一异常处理

**常见问题**：
- 将堆栈信息直接返回
- 错误页面显示数据库错误
- 登录失败、权限拒绝等安全事件未记录
- 生产环境使用 DEBUG 日志级别
- 日志未做访问控制

**检查方法**（Windows PowerShell）：
```powershell
# 搜索异常处理
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "@ControllerAdvice|@ExceptionHandler|try\s*\{|catch\s*\("

# 搜索日志中的敏感信息
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "log\.(info|debug|warn|error)\(.*password|log\.(info|debug|warn|error)\(.*token"
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts -ExcludeDir $ExcludeDirs | Select-String -Pattern "System\.out\.print|console\.log"
```

**修复建议**：
- 配置全局异常处理器，返回通用错误信息
- 记录关键安全事件（登录、登出、权限拒绝、数据访问）
- 生产环境使用 INFO 及以上级别
- 日志文件设置访问权限
- 接入日志监控系统（ELK、Splunk）

**CWE 参考**：CWE-209（错误信息泄露）、CWE-778（日志不足）

---

##### 4.4 业务逻辑漏洞检查

**OWASP 对应**：A04:2021-Insecure Design

**检查目标**：识别业务流程中的安全缺陷

**检查要点**：
- 是否有绕过业务流程的方式
- 是否有重复提交风险
- 是否有并发竞争条件
- 是否有业务规则绕过（如负数金额、超大数量）
- 是否有时间窗口漏洞

**常见问题**：
- 支付金额可被篡改
- 优惠券可重复使用
- 库存扣减存在并发问题
- 订单状态可被非法跳过
- 优惠叠加无上限

**检查方法**（Windows PowerShell）：
```powershell
# 搜索关键业务参数
Get-ChildItem -Path . -Recurse -Include *.java,*.js,*.ts,*.py,*.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "price|amount|quantity|stock|discount|coupon"

# 搜索并发控制
Get-ChildItem -Path . -Recurse -Include *.java -ExcludeDir $ExcludeDirs | Select-String -Pattern "synchronized|Lock|ReentrantLock|atomic|volatile"
Get-ChildItem -Path . -Recurse -Include *.go -ExcludeDir $ExcludeDirs | Select-String -Pattern "mutex|Lock|atomic|channel"
```

**修复建议**：
- 关键参数（如金额）从服务端计算，禁止客户端传递
- 敏感操作添加幂等性控制
- 使用数据库锁或分布式锁处理并发
- 完整的业务规则校验
- 关键操作添加审计日志

**CWE 参考**：CWE-840（业务逻辑错误）、CWE-670（始终不为真的漏洞）

---

## 输出格式

### Step 5 - 生成检查报告并保存文件

**重要**：检查结果必须保存为文件，便于后续跟踪和审计。

**保存路径格式**：
```
<项目根目录>/docs/代码安全检查结果/code-security-report-YYYYMMDD-HHmmss.md
```

**示例**：
```
D:\my-project\docs\代码安全检查结果\code-security-report-20260622-153045.md
```

**执行步骤**：
1. 在项目根目录创建 `docs/代码安全检查结果/` 目录（如果不存在）
2. 生成报告文件，文件名包含时间戳
3. 将检查结果写入文件
4. 同时在终端输出检查结果摘要

**报告内容格式**：

```markdown
# 代码安全检查报告

## 检查概要
- 检查时间：[YYYY-MM-DD HH:mm:ss]
- 检查范围：[文件/目录]
- 项目类型：[Java/Python/Node.js 等]
- 代码行数：[总行数]
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

## 检查原则

1. **全面性**：覆盖所有代码文件，包括配置文件、测试代码、脚本
2. **准确性**：确保每个问题都有明确的代码位置和证据，避免误报
3. **可操作性**：提供具体的修复建议，避免空泛的指导
4. **优先级**：按风险等级排序，优先报告严重和高危问题
5. **上下文**：结合业务场景评估风险，避免脱离实际的建议
6. **可追溯**：每个问题对应 OWASP/CWE 分类，便于统计和跟踪

## 特别注意事项

1. **脱敏处理**：检查结果中如需引用敏感信息，需脱敏处理（如 `password=***`）
2. **误报处理**：如发现误报，需说明原因并从报告中移除
3. **业务理解**：结合业务逻辑评估风险，某些"问题"可能是业务需要
4. **修复可行性**：修复建议需考虑实际可操作性，避免不切实际的建议
5. **遗留风险**：如存在暂时无法修复的问题，需说明原因和后续计划
6. **测试验证**：修复后需进行验证测试，确保问题已修复且未引入新问题

## 参考标准

- **OWASP Top 10 2021**：Web 应用安全风险 Top 10
- **CWE/SANS Top 25**：最危险的软件错误
- **GB/T 22239-2019**：信息安全技术 网络安全等级保护基本要求
- **OWASP Code Review Guide**：代码审查指南
- **OWASP ASVS**：应用安全验证标准