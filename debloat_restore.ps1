$apps = @(
    "com.miui.gallery",
    "com.miui.securitycenter",
    "com.lbe.security.miui",
    "com.miui.securityadd",
    "com.miui.permission",
    "com.android.providers.media.module",
    "com.android.providers.media",
    "com.android.settings"
)

Write-Host "===================================================" -ForegroundColor Green
Write-Host " HyperOS Essential App Restorer" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green

foreach ($app in $apps) {
    Write-Host "`nAttempting to restore: $app" -ForegroundColor Cyan

    # The standard restore command with explicit user 0 targeting
    adb shell pm install-existing --user 0 $app

    # Enable the package
    adb shell pm enable --user 0 $app
}

Write-Host "`n===================================================" -ForegroundColor Green
Write-Host " Restoration commands complete. Please restart device." -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Green