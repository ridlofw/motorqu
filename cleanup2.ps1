$root = "D:\Ridlo\Belajar\tanya-opencode\oli-tracker"
$junk = @("checkapk.ps1", "dl_gsvc.ps1", "add_sha_correct.ps1", "build_log.ps1", "build.log", "rlog.ps1", "fix_spec.ps1", "gsvc_raw.json")
foreach ($j in $junk) {
    $p = Join-Path $root $j
    if (Test-Path $p) { Remove-Item $p -Force; Write-Output "removed $j" }
}
Write-Output "cleanup done"