# 隐藏环境模块下载 (PowerShell)  -- 放到 E:\alioth_ksu\modules
$M = "E:\alioth_ksu\modules"; New-Item -ItemType Directory -Force -Path $M | Out-Null
function Get-Rel($repo,$pattern,$out){
  $r = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
  $a = $r.assets | Where-Object { $_.name -like $pattern } | Select-Object -First 1
  if($a){ Invoke-WebRequest $a.browser_download_url -OutFile "$M\$out"; Write-Host "[+] $out <- $($a.name)" }
  else { Write-Host "[!] $repo 无匹配 $pattern" }
}
Get-Rel "Dr-TSNG/ZygiskNext"              "*.zip" "ZygiskNext.zip"
Get-Rel "LSPosed/LSPosed"                 "*.zip" "LSPosed-zygisk.zip"
Get-Rel "chiteroman/PlayIntegrityFix"     "*.zip" "PlayIntegrityFix.zip"
Get-Rel "5ec1cff/TrickyStore"             "*.zip" "TrickyStore.zip"
Write-Host "Shamiko 需从 KernelSU 官方群/GitHub LSPosed 组织 Release 取: LSPosed/LSPosed -> Shamiko 单独仓库"
Write-Host "完成后: adb push 到 /sdcard, 在 KernelSU Manager 模块页逐个安装"
