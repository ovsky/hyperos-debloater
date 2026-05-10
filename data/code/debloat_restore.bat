@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=40
title Xiaomi HyperOS Restorer

:: Physically navigate to resolve bulletproof paths
cd /d "%~dp0"
cd ..\..
set "ROOT_DIR=%cd%"
set "CONFIG_PATH=%cd%\data\config\config.json"
cd /d "%~dp0"

:: Validate JSON using absolute path
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: "%CONFIG_PATH%" contains syntax errors or is missing.
    pause & exit
)

:: Secure JSON to Batch variable extraction via temporary script
set "TEMP_VARS=%temp%\hyperos_vars_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $out = @(); $out += 'set \"ADB_PATH=' + $c.settings.defaultAdbPath + '\"'; $out += 'set \"apps_p1=' + ($c.phases.phase1_safe -join ' ') + '\"'; $out += 'set \"apps_p2=' + ($c.phases.phase2_advanced -join ' ') + '\"'; $out += 'set \"apps_p3=' + ($c.phases.phase3_risky -join ' ') + '\"'; $out += 'set \"apps_p4=' + ($c.phases.phase4_hidden -join ' ') + '\"'; $out += 'set \"apps_restore_only=' + ($c.phases.restore_only -join ' ') + '\"'; $out | Set-Content -Path '%TEMP_VARS%' -Encoding ASCII"
call "%TEMP_VARS%"
del "%TEMP_VARS%"

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