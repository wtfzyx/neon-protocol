$ErrorActionPreference = 'Continue'
$env:GCM_INTERACTIVE = 'never'
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class CredManP {
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
[CredManP]::CredRead($t, 1, 0, [ref]$p) | Out-Null
$c = [Runtime.InteropServices.Marshal]::PtrToStructure($p, [type][CredManP+CREDENTIAL])
$sz = $c.CredentialBlobSize
$b = New-Object byte[] $sz
[Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $b, 0, $sz)
[CredManP]::CredFree($p) | Out-Null
$token = [Text.Encoding]::UTF8.GetString($b).Trim()
$auth = @("Authorization: token $token", 'User-Agent: codex', 'Accept: application/vnd.github+json')

for ($i = 1; $i -le 20; $i++) {
  $raw = curl.exe -s -w "`nHTTP_%{http_code}" -H $auth[0] -H $auth[1] -H $auth[2] --max-time 25 "https://api.github.com/repos/wtfzyx/neon-protocol/releases?per_page=10"
  $lines = $raw -split "`n"
  $status = $lines[-1]
  $body = $lines[0..($lines.Length-2)] -join "`n"
  $snippet = if ($body.Length -gt 60) { $body.Substring(0,60) } else { $body }
  Write-Host "attempt $i : $status | body: $snippet"
  if ($status -match 'HTTP_200' -and $body.Trim().StartsWith('[')) {
    try {
      $releases = $body | ConvertFrom-Json
      if ($releases.Count -gt 0) {
        Write-Host "SUCCESS, releases: $($releases.Count)"
        $v101 = @($releases | Where-Object { $_.tag_name -eq 'v1.0.1' })
        Write-Host "v1.0.1 entries: $($v101.Count)"
        foreach ($r in $v101) {
          Write-Host ("  id={0} draft={1} assets={2}" -f $r.id, $r.draft, $r.assets.Count)
          foreach ($a in $r.assets) { Write-Host ("     asset: {0} id={1}" -f $a.name, $a.id) }
        }
        break
      }
    } catch { Write-Host "  parse error" }
  }
  Start-Sleep -Seconds 5
}