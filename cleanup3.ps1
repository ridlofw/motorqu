$root = "D:\Ridlo\Belajar\tanya-opencode\oli-tracker"
$junk = @(
    "cleanup.ps1", "cleanup2.ps1", "MotorQu-v1.0.0.apk",
    "build.log", "pubget.log", "icons.log", "build.log.ps1",
    "add_icons.ps1", "checkapk.ps1", "dl_gsvc.ps1",
    "add_sha_correct.ps1", "fix_spec.ps1", "rlog.ps1",
    "gsvc_raw.json", "check_gsvc.ps1", "dump_gsvc.ps1",
    "get_sha1.ps1", "add_sha1.ps1", "add_sha1b.ps1", "add_sha1c.ps1",
    "readlog.ps1", "readlog2.ps1", "fix_profile.ps1",
    "fix_snack.ps1", "fix_snack2.ps1", "fix_snack3.ps1",
    "gen_home.ps1", "gen_group.ps1", "gen_profile.ps1",
    "gen_notif.ps1", "gen_add_motor.ps1", "append_home.ps1",
    "repair.ps1", "repair2.ps1", "repair3.ps1", "nope.ps1"
)
foreach ($j in $junk) {
    $p = Join-Path $root $j
    if (Test-Path $p) { Remove-Item $p -Force }
}
Write-Output "cleanup done"