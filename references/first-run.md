# 首次配置指南

## 个人偏好

将用户的个人偏好保存到 ~/.codex/skill-settings/xiaohongshu-hotvideo.json。这里的 ~ 是当前系统用户的主目录。例如：

```json
{
  "linkCount": 10,
  "downloadRoot": "D:\\视频素材\\小红书"
}
```

linkCount 为正整数，downloadRoot 为用户输入的 Windows 本地绝对目录路径。检查盘符存在；如果给出的路径指向文件或使用相对路径，请用户重新输入。目标文件夹可以尚未建立，下载时由脚本创建。保存时用 JSON 序列化处理反斜杠，合并已收到的有效字段。旧配置只有 linkCount 时保留原数量，补存 downloadRoot。个人偏好写在技能目录之外，分步配置时仅继续询问缺失或无效的项目。后续启动以实际可用的连接为准。

## Monid

使用用户本机的 Monid CLI。若 CLI 未安装，参考[官方安装说明](https://docs.monid.ai/cli/overview.html)。请用户到 [Monid API Keys](https://app.monid.ai/access/api-keys) 生成 Key，在自己的 PowerShell 7 窗口执行以下命令，并在隐藏输入提示中粘贴 Key。

```powershell
$monidCli = (Get-Command monid -ErrorAction SilentlyContinue).Source
if (!$monidCli) { $monidCli = Join-Path $env:APPDATA 'npm/monid.cmd' }
if (!(Test-Path -LiteralPath $monidCli)) { throw '请先安装 Monid CLI。' }
$monidKey = Read-Host '粘贴 Monid API Key' -MaskInput
try {
    & $monidCli keys add --label xiaohongshu-hotvideo --key $monidKey
    if ($LASTEXITCODE -ne 0) { throw 'Monid Key 添加失败，请检查 CLI 提示。' }
} finally {
    Remove-Variable monidKey -ErrorAction SilentlyContinue
}
```

已有自己的 Monid 凭据可直接沿用。CLI 有多个 Key 时，检查用户要使用的标签。按本机 CLI 帮助使用指定 Key；需要切换时，让用户在终端运行 monid keys activate --label xiaohongshu-hotvideo（这会更改 CLI 的默认 Key）。用 monid balance 验证本次使用的账号可认证，无需发起付费搜索。汇报时只返回可用状态，不返回密钥材料。

## Apify

已连接自己的 Apify 账号时可以直接复用。使用 API Token 时，请用户在 [Apify API & Integrations](https://console.apify.com/settings/integrations) 获取 Token，再在自己的 Windows PowerShell 7 窗口执行下面的命令。该命令在当前 Windows 用户的环境变量中保存 Token。

```powershell
$apifyToken = Read-Host '粘贴 Apify API Token' -MaskInput
try {
    if ([string]::IsNullOrWhiteSpace($apifyToken)) { throw 'Apify API Token 不能为空。' }
    [Environment]::SetEnvironmentVariable('XIAOHONGSHU_HOTVIDEO_APIFY_TOKEN', $apifyToken, 'User')
} finally {
    Remove-Variable apifyToken -ErrorAction SilentlyContinue
}
```

在 Codex 的用户配置 config.toml 中添加以下 MCP 配置。只添加此节，保留其他设置。已经存在同名节时更新其 URL 和环境变量引用。

```toml
[mcp_servers.xiaohongshu_hotvideo_apify]
url = "https://mcp.apify.com?tools=actors,agentflow/xiaohongshu-video-downloader"
bearer_token_env_var = "XIAOHONGSHU_HOTVIDEO_APIFY_TOKEN"
```

完全退出并重新打开 Codex，让新进程继承环境变量并加载 MCP 配置。发现该连接后，用 fetch-actor-details 或等效的只读工具检查 Actor agentflow/xiaohongshu-video-downloader 是否能在该连接上访问。只有明确要求下载视频时才运行 Actor。工具尚未加载或认证失败时说明当前卡在哪一步；仅凭用户回复「已配置」不宣称连接已验证。

参考 [Apify MCP 认证及工具配置](https://docs.apify.com/mcp)。
