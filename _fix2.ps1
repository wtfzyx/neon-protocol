$ErrorActionPreference = 'Continue'
$env:GCM_INTERACTIVE = 'never'
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class CredManQ {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags; public int Type; public IntPtr TargetName; public IntPtr Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize; public IntPtr CredentialBlob;
        public int Persist; public int AttributeCount; public IntPtr Attributes;
        public IntPtr TargetAlias; public IntPtr UserName;
    }
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reserved, out IntPtr credential);
    [DllImport("advapi32.dll")]
    public static extern void CredFree(IntPtr buffer);
}
"@
$t = 'GitHub - https://api.github.com/wtfzyx'
$p = [IntPtr]::Zero
[CredManQ]::CredRead($t, 1, 0, [ref]$p) | Out-Null
$c = [Runtime.InteropServices.Marshal]::PtrToStructure($p, [type][CredManQ+CREDENTIAL])
$sz = $c.CredentialBlobSize
$b = New-Object byte[] $sz
[Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $b, 0, $sz)
[CredManQ]::CredFree($p) | Out-Null
$token = [Text.Encoding]::UTF8.GetString($b).Trim()
$auth = @("Authorization: token $token", 'User-Agent: codex', 'Accept: application/vnd.github+json')

$mainId = 371788771
$dupId  = 371788772
$bmAssetId = 518182272

# 1) 下载 blockmap（带重试）
$bmPath = Join-Path $env:TEMP 'NeonProtocol-Setup-1.0.1.exe.blockmap'
for ($i = 1; $i -le 6; $i++) {
  curl.exe -s -L -H $auth[0] -H $auth[1] -H "Accept: application/octet-stream" --max-time 60 -o $bmPath "https://api.github.com/repos/wtfzyx/neon-protocol/releases/assets/$bmAssetId"
  if ((Test-Path $bmPath) -and (Get-Item $bmPath).Length -gt 10000) { Write-Host "blockmap downloaded: $((Get-Item $bmPath).Length) bytes"; break }
  Write-Host "blockmap download retry $i"
  Start-Sleep -Seconds 3
}

# 2) 上传 blockmap 到主草稿
$upUrl = "https://uploads.github.com/repos/wtfzyx/neon-protocol/releases/$mainId/assets?name=NeonProtocol-Setup-1.0.1.exe.blockmap"
$up = curl.exe -s -w "`nHTTP_%{http_code}" -X POST -H $auth[0] -H $auth[1] -H "Content-Type: application/octet-stream" --data-binary "@$bmPath" --max-time 120 $upUrl
Write-Host "blockmap upload: $(($up -split "`n")[-1])"
Remove-Item -LiteralPath $bmPath -Force -ErrorAction SilentlyContinue

# 3) 删除重复草稿
$del = curl.exe -s -o NUL -w "HTTP_%{http_code}" -X DELETE -H $auth[0] -H $auth[1] --max-time 40 "https://api.github.com/repos/wtfzyx/neon-protocol/releases/$dupId"
Write-Host "delete dup: $del"

# 4) 发布主草稿
$patch = '{"draft":false}'
$pub = curl.exe -s -w "`nHTTP_%{http_code}" -X PATCH -H $auth[0] -H $auth[1] -H "Content-Type: application/json" -d $patch --max-time 40 "https://api.github.com/repos/wtfzyx/neon-protocol/releases/$mainId"
$pubLines = $pub -split "`n"
Write-Host "publish: $($pubLines[-1])"
$pubJson = $pubLines[0..($pubLines.Length-2)] -join "`n"
if ($pubJson -match '"html_url"\s*:\s*"([^"]+)"') { Write-Host "page: $($Matches[1])" }