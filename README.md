# 小红书同款高赞视频助手
把这句话发给 Codex 安装
https://github.com/kyy338/xiaohongshu-hotvideo

上传一张商品图，Codex 会在小红书上找同款视频，按搜索时的点赞数排序，并把核实后能下载的视频存到电脑里。你可以设置每次想找多少条，以及视频保存到哪里。

## 1. 下载并安装技能

1. 用有仓库访问权限的 GitHub 账号打开本页。点击 **Code → Download ZIP**，下载后解压。
2. 按 **Win + R**，输入 `%USERPROFILE%\.codex`，按回车。在打开的文件夹中找到 `skills`，没有就新建一个。
3. 把解压出来、直接包含 `SKILL.md` 的整个文件夹复制到 `skills` 下，并把文件夹改名为 `xiaohongshu-hotvideo`。保留里面的 `agents`、`references` 和 `scripts`。
4. 打开一个新的 Codex 本地对话。在输入框中输入 `$xiaohongshu-hotvideo`，选中技能并发送。若列表里没出现，先确认 `SKILL.md` 直接位于 `skills\xiaohongshu-hotvideo` 下，再重启 Codex。

## 2. 准备运行工具

这份指南适用于 Windows 本地环境。安装后，在开始菜单打开 **PowerShell 7**，可以用下面的命令检查各工具是否可用。

| 工具 | 用途 | 检查方式 |
| --- | --- | --- |
| [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/install-powershell-on-windows) | 运行配置和保存命令 | `pwsh --version` |
| [Node.js](https://nodejs.org/en/download) | 提供安装 Monid CLI 所需的 npm | `npm.cmd --version` |
| [Monid CLI](https://docs.monid.ai/cli/overview.html) | 搜索小红书视频 | `monid --version` |
| [FFmpeg 的 Windows 版本](https://ffmpeg.org/download.html#build-windows) | 提供检查 MP4 文件的 `ffprobe.exe` | `ffprobe -version` |

装好 Node.js 后，在 PowerShell 7 运行 `npm.cmd install -g @monid-ai/cli`。安装 FFmpeg 后，把包含 `ffprobe.exe` 的目录加入 Windows 用户的 **Path** 环境变量。安装工具或修改 Path 后，重新打开终端和 Codex，再检查一次。

## 3. 回答首次配置的四个问题

| Codex 会问什么 | 你怎么回答 |
| --- | --- |
| **每次找多少条链接？** | 填一个正整数，例如 `10`。同款不足时，会按实际核实的数量交付。 |
| **Monid API Key 配好了吗？** | 没配过就去 [Monid API Keys](https://app.monid.ai/access/api-keys) 创建 Key，按[配置指南的 Monid 步骤](references/first-run.md#monid)在本机录入，然后回复「Monid 已配置」。 |
| **Apify API Token 配好了吗？** | 已有自己的 Apify MCP 连接可以直接沿用。否则到 [Apify API & Integrations](https://console.apify.com/settings/integrations) 获取 Token，按[配置指南的 Apify 步骤](references/first-run.md#apify)在本机录入并加入 MCP 设置。重启 Codex 后回复「Apify 已配置」。 |
| **视频默认保存在哪里？** | 填一个本地文件夹的完整路径，例如 `C:\视频素材\小红书`。文件夹尚未创建时，下载会自动创建。 |

你可以先回复数量和目录，再配置两个账号。密钥只填在自己电脑的终端提示里，聊天中回复配置状态即可。如果重启 Codex 后需要继续配置，重新调用技能，已保存的数量和目录会自动读入。

## 4. 第一次找视频

把一张清晰的商品照片上传到 Codex 对话，再发送：

> 用 $xiaohongshu-hotvideo 根据这张图找同款小红书视频，按点赞数排序并下载。

任务结束后，Codex 会告诉你找到了多少条、下载了多少条，以及保存在哪里。假如你选择的目录是 `C:\视频素材\小红书`，商品名是「棕色围巾」，下载结果会放在 `C:\视频素材\小红书\棕色围巾` 下。文件名形如 `5599.mp4`，数字是该视频的点赞数。Monid 搜索和 Apify 下载可能产生用量费用。

以后换一张商品图，发同样的指令就可以了。想临时改数量或目录，直接说「这次找 5 条，保存到 `C:\临时素材`」。想让新设置以后也生效，加一句「设为默认」。

## 常见问题

- **Codex 找不到 `monid`**：重新打开终端，运行 `monid --version`。如果命令仍找不到，尝试 `& "$env:APPDATA\npm\monid.cmd" --version`。两条都失败时，重新检查 Monid CLI 是否安装成功。
- **只有链接，没有视频文件**：先检查 Apify MCP 是否连接成功，再确认 `ffprobe -version` 能运行，以及保存目录所在的盘符可用。
- **找到的链接比设定数量少**：技能只交付能核实是同款的视频。可以换一张更清楚的商品照片，或者在消息里补充品牌、型号和颜色。
