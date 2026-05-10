@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=40
title Xiaomi HyperOS Restorer
cd /d "%~dp0"

:: Set absolute paths resolving from the code directory
set "ROOT_DIR=%~dp0..\.."
set "CONFIG_PATH=%~dp0..\config\config.json"

:: Validate JSON
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: %CONFIG_PATH% contains syntax errors or is missing.
    pause & exit
)

:: Fetch apps and adb path from JSON
for /f "tokens=1,* delims==" %%A in ('powershell -NoProfile -Command "& { $c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; Write-Output \"ADB_PATH=$($c.settings.defaultAdbPath)\"; Write-Output \"apps_p1=$($c.phases.phase1_safe -join ' ')\"; Write-Output \"apps_p2=$($c.phases.phase2_advanced -join ' ')\"; Write-Output \"apps_p3=$($c.phases.phase3_risky -join ' ')\"; Write-Output \"apps_p4=$($c.phases.phase4_hidden -join ' ')\"; Write-Output \"apps_restore_only=$($c.phases.restore_only -join ' ')\" }"') do (
    set "%%A=%%B"
)

:: Ensure ADB command is absolute resolving to root
set "ADB_CMD=!ADB_PATH!"
if exist "%ROOT_DIR%\!ADB_PATH!" set "ADB_CMD="%ROOT_DIR%\!ADB_PATH!""

:: Combine all packages
set "ALL_APPS=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only% com.xiaomi.joyose"

:: ANSI Colors
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BG_GRN=%ESC%[42m%ESC%[30m"
set "TXT_CYAN=%ESC%[96m"
set "TXT_GRN=%ESC%[92m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_GRN%  HYPEROS ESSENTIAL APP RESTORER                                                                                    %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%Connecting to ADB...%RESET%
!ADB_CMD! start-server >nul 2>&1
!ADB_CMD! wait-for-device

echo  %TXT_GRN%[+] Device Connected. Beginning Full Restoration Sequence...%RESET%
echo.

for %%a in (%ALL_APPS%) do (
    echo  %TXT_GRAY%Attempting to restore:%RESET% %TXT_WHT%%%a%RESET%
    !ADB_CMD! shell cmd package install-existing --user 0 %%a >nul 2>&1
    !ADB_CMD! shell pm enable --user 0 %%a >nul 2>&1
)

echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_GRN%  RESTORATION COMPLETE                                                                                              %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_WHT%Please restart your device to ensure all system apps reinitialize properly.%RESET%
echo.
pause