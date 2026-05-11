@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=40
title Xiaomi HyperOS Restorer

:: Secure absolute paths
for %%A in ("%~dp0..\..") do set "ROOT_DIR=%%~fA"
set "CONFIG_PATH=%ROOT_DIR%\data\config\config.json"
set "SERVICES_PATH=%ROOT_DIR%\data\config\services.json"

:: Validate JSON using absolute path
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: One of your JSON files contains syntax errors or is missing.
    pause & exit
)

:: Securely dump JSON variables directly into Batch
set "TEMP_VARS=%temp%\hyperos_vars_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json; 'set ADB_PATH=' + $c.settings.defaultAdbPath; 'set SIM_MODE=' + [int][bool]$c.settings.simulationMode; 'set REBOOT_RESTORE=' + [int][bool]$c.settings.rebootAfterRestore; 'set apps_p1=' + ($s.phases.phase1_safe -join ' '); 'set apps_p2=' + ($s.phases.phase2_advanced -join ' '); 'set apps_p3=' + ($s.phases.phase3_risky -join ' '); 'set apps_p4=' + ($s.phases.phase4_hidden -join ' '); 'set apps_restore_only=' + ($s.phases.restore_only -join ' ')" > "%TEMP_VARS%"
call "%TEMP_VARS%"
del "%TEMP_VARS%"

:: Ensure ADB command is absolute
set "ADB_CMD=!ADB_PATH!"
if exist "%ROOT_DIR%\!ADB_PATH!" set "ADB_CMD=%ROOT_DIR%\!ADB_PATH!"

:: Combine all packages
set "ALL_APPS=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only% com.xiaomi.joyose"

:: ANSI Colors
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "BG_CYAN=%ESC%[46m%ESC%[30m"
set "BG_GRN=%ESC%[42m%ESC%[30m"
set "BG_RED=%ESC%[41m%ESC%[97m"
set "TXT_CYAN=%ESC%[96m"
set "TXT_GRN=%ESC%[92m"
set "TXT_YEL=%ESC%[93m"
set "TXT_MAG=%ESC%[95m"
set "TXT_RED=%ESC%[91m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

"!ADB_CMD!" start-server >nul 2>&1

:: ===============================================================================================
::  AUTO-SCANNING DEVICE CONNECTION
:: ===============================================================================================
:CHECK_DEVICES
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_GRN%  HYPEROS ESSENTIAL APP RESTORER                                                                                    %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
if "!SIM_MODE!"=="1" echo  %TXT_MAG%  [DEBUG SIMULATION MODE ACTIVE] Commands will not be executed.%RESET%
echo.
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                      %RESET%
echo  %TXT_GRAY%Auto-scanning for connected devices...%RESET%
echo  %TXT_GRAY%Ensure USB Debugging is ON.%RESET%
echo.
echo  Press %TXT_RED%[E]%RESET% to cancel and return to Manager.

set count=0
for /f "skip=1 tokens=1,2,*" %%a in ('"!ADB_CMD!" devices -l') do (
    if "%%b" == "device" (
        set /a count+=1
        set "device[!count!]=%%a"
        for /f "tokens=*" %%m in ('"!ADB_CMD!" -s %%a shell getprop ro.product.model') do set "model[!count!]=%%m"
    )
)

if !count! GTR 0 (
    set "TARGET_ID=!device[1]!"
    set "TARGET_MODEL=!model[1]!"
    echo.
    echo  %TXT_GRN%  [v]%RESET% Connected Model: %TXT_WHT%!TARGET_MODEL!%RESET%
    timeout /t 2 >nul
    goto RESTORE_SEQUENCE
)

:: Wait 2 seconds, default to R (Retry), exit if user presses E
choice /c RE /n /t 2 /d R >nul
if errorlevel 2 goto :eof
goto CHECK_DEVICES

:: ===============================================================================================
::  RESTORATION
:: ===============================================================================================
:RESTORE_SEQUENCE
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_GRN%  HYPEROS ESSENTIAL APP RESTORER                                                                                    %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRN%[+] Device Connected. Beginning Full Restoration Sequence...%RESET%
echo.

for %%a in (%ALL_APPS%) do (
    echo  %TXT_GRAY%Attempting to restore:%RESET% %TXT_WHT%%%a%RESET%
    if "!SIM_MODE!"=="1" (
        echo  %TXT_MAG%[DEBUG]%RESET% "!ADB_CMD!" -s !TARGET_ID! shell cmd package install-existing --user 0 %%a
        echo  %TXT_MAG%[DEBUG]%RESET% "!ADB_CMD!" -s !TARGET_ID! shell pm enable --user 0 %%a
    ) else (
        "!ADB_CMD!" -s !TARGET_ID! shell cmd package install-existing --user 0 %%a >nul 2>&1
        "!ADB_CMD!" -s !TARGET_ID! shell pm enable --user 0 %%a >nul 2>&1
    )
)

echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_GRN%  RESTORATION COMPLETE                                                                                              %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.

if "!REBOOT_RESTORE!"=="1" (
    echo  %TXT_CYAN%Auto-Reboot is enabled. Rebooting device...%RESET%
    if "!SIM_MODE!"=="1" (
        echo  %TXT_MAG%[DEBUG]%RESET% "!ADB_CMD!" -s !TARGET_ID! reboot
    ) else (
        "!ADB_CMD!" -s !TARGET_ID! reboot
    )
) else (
    echo  %TXT_WHT%Please restart your device manually to ensure all system apps reinitialize properly.%RESET%
)

echo.
pause