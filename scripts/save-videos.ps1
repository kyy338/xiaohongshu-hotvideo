param(
    [Parameter(Mandatory)][string]$ManifestPath,
    [string]$Root
)

$ErrorActionPreference = 'Stop'
if (!$PSBoundParameters.ContainsKey('Root')) {
    $settingsPath = Join-Path $HOME '.codex/skill-settings/xiaohongshu-hotvideo.json'
    if (!(Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        throw '请先设置默认视频保存目录，或用 -Root 指定本次目录。'
    }
    $settings = Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json
    $Root = $settings.downloadRoot
}
if ($Root -notmatch '^[A-Za-z]:[\\/]' -or ![IO.Path]::IsPathFullyQualified($Root)) {
    throw '请输入包含盘符的本地绝对目录路径。'
}
$rootPath = [IO.Path]::GetFullPath($Root)
if (!(Test-Path -LiteralPath ([IO.Path]::GetPathRoot($rootPath)) -PathType Container)) {
    throw "保存目录所在盘符不可用：$rootPath"
}
if (Test-Path -LiteralPath $rootPath -PathType Leaf) {
    throw "保存路径是文件，请指定文件夹：$rootPath"
}
$probe = (Get-Command ffprobe.exe -CommandType Application).Source
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $ManifestPath | ConvertFrom-Json
$product = ([string]$manifest.product -replace '[<>:"/\\|?*\x00-\x1f]', ' ').Trim().TrimEnd('. ')
if (!$product -or $product -match '^(CON|PRN|AUX|NUL|COM[1-9¹²³]|LPT[1-9¹²³])(\.|$)') {
    throw '产品目录名称无效。'
}
$folder = Join-Path $rootPath $product
[void][IO.Directory]::CreateDirectory($folder)

foreach ($video in $manifest.videos) {
    $id = [string]$video.id
    $temporary = $null
    try {
        if ($id -notmatch '^[a-f0-9]{24}$' -or [string]$video.likes -notmatch '^\d+$') {
            throw '笔记 ID 或点赞数无效。'
        }
        $url = [uri]$video.downloadUrl
        if (!$url.IsAbsoluteUri -or $url.Scheme -ne 'https') {
            throw '视频地址须为 HTTPS。'
        }

        $temporary = Join-Path $folder ('.' + [guid]::NewGuid().ToString('N') + '.part')
        Invoke-WebRequest -Uri $url -OutFile $temporary -TimeoutSec 120

        $format = & $probe -v error -select_streams v:0 -show_entries stream=codec_type:format=format_name -of json $temporary 2>$null
        if ($LASTEXITCODE -ne 0) { throw '下载文件无法作为视频读取。' }
        $media = ($format -join "`n") | ConvertFrom-Json
        if ('mp4' -notin ($media.format.format_name -split ',') -or 'video' -notin $media.streams.codec_type) {
            throw '下载文件缺少 MP4 容器或视频流。'
        }

        $baseName = [string]$video.likes
        $destination = Join-Path $folder "$baseName.mp4"
        $index = 1
        while ($true) {
            try {
                [IO.File]::Move($temporary, $destination)
                break
            } catch [IO.IOException] {
                if (![IO.File]::Exists($destination)) { throw }
                $suffix = if ($index -eq 1) { $id } else { "$id-$index" }
                $destination = Join-Path $folder "$baseName-$suffix.mp4"
                $index++
            }
        }
        [pscustomobject]@{ id = $id; status = 'saved'; path = $destination } | ConvertTo-Json -Compress
    } catch {
        [pscustomobject]@{ id = $id; status = 'failed'; reason = $_.Exception.Message } | ConvertTo-Json -Compress
    } finally {
        if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

