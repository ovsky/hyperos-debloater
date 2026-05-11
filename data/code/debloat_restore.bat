@echo off\r
setlocal EnableDelayedExpansion\r
mode con: cols=120 lines=40\r
title Xiaomi HyperOS Restorer\r
\r
:: Secure absolute paths\r
for %%A in ("%~dp0..\..\") do set "ROOT_DIR=%%~fA"\r
set "CONFIG_PATH=%ROOT_DIR%\data\config\config.json"\r
set "SERVICES_PATH=%ROOT_DIR%\data\config\services.json"\r
\r
:: Validate JSON using absolute path\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json" >nul 2>&1\r
if %errorlevel% neq 0 (\r
    echo [!] ERROR: One of your JSON files contains syntax errors or is missing.\r
    pause & exit\r
)\r
\r
:: Securely dump JSON variables directly into Batch\r
set "TEMP_VARS=%temp%\hyperos_vars_%RANDOM%.cmd"\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json; 'set ADB_PATH=' + $c.settings.defaultAdbPath; 'set SIM_MODE=' + [int][bool]$c.settings.simulationMode; 'set REBOOT_RESTORE=' + [int][bool]$c.settings.rebootAfterRestore; 'set apps_p1=' + ($s.phases.phase1_safe -join ' '); 'set apps_p2=' + ($s.phases.phase2_advanced -join ' '); 'set apps_p3=' + ($s.phases.phase3_risky -join ' '); 'set apps_p4=' + ($s.phases.phase4_hidden -join ' '); 'set apps_restore_only=' + ($s.phases.restore_only -join ' ')" > "%TEMP_VARS%"\r
call "%TEMP_VARS%"\r
del "%TEMP_VARS%"\r
\r
:: Ensure ADB command is absolute\r
set "ADB_CMD=!ADB_PATH!"\r
if exist "%ROOT_DIR%\!ADB_PATH!" set "ADB_CMD=%ROOT_DIR%\!ADB_PATH!"\r
\r
:: Combine all packages\r
set "ALL_APPS=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only% com.xiaomi.joyose"\r
\r
:: ANSI Colors\r
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"\r
set "RESET=%ESC%[0m"\r
set "BOLD=%ESC%[1m"\r
set "BG_CYAN=%ESC%[46m%ESC%[30m"\r
set "BG_GRN=%ESC%[42m%ESC%[30m"\r
set "BG_RED=%ESC%[41m%ESC%[97m"\r
set "TXT_CYAN=%ESC%[96m"\r
set "TXT_GRN=%ESC%[92m"\r
set "TXT_YEL=%ESC%[93m"\r
set "TXT_MAG=%ESC%[95m"\r
set "TXT_RED=%ESC%[91m"\r
set "TXT_GRAY=%ESC%[90m"\r
set "TXT_WHT=%ESC%[97m"\r
\r
"!ADB_CMD!" start-server >nul 2>&1\r
\r
:: ===============================================================================================\r
::  AUTO-SCANNING DEVICE CONNECTION\r
:: ===============================================================================================\r
:CHECK_DEVICES\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BG_GRN%  HYPEROS ESSENTIAL APP RESTORER                                                                                    %RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
if "!SIM_MODE!"=="1" echo  %TXT_MAG%  [DEBUG SIMULATION MODE ACTIVE] Commands will not be executed.%RESET%\r
echo.\r
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                      %RESET%\r
echo  %TXT_GRAY%Auto-scanning for connected devices...%RESET%\r
echo  %TXT_GRAY%Ensure USB Debugging is ON.%RESET%\r
echo.\r
echo  Press %TXT_RED%[E]%RESET% to cancel and return to Manager.\r
\r
set count=0\r
for /f "skip=1 tokens=1,2,*" %%a in ('"!ADB_CMD!" devices -l') do (\r
    if "%%b" == "device" (\r
        set /a count+=1\r
        set "device[!count!]=%%a"\r
        for /f "tokens=*" %%m in ('"!ADB_CMD!" -s %%a shell getprop ro.product.model') do set "model[!count!]=%%m"\r
    )\r
)\r
\r
if !count! GTR 0 (\r
    set "TARGET_ID=!device[1]!"\r
    set "TARGET_MODEL=!model[1]!"\r
    echo.\r
    echo  %TXT_GRN%  [v]%RESET% Connected Model: %TXT_WHT%!TARGET_MODEL!%RESET%\r
    timeout /t 2 >nul\r
    goto RESTORE_SEQUENCE\r
)\r
\r
:: Wait 2 seconds, default to R (Retry), exit if user presses E\r
choice /c RE /n /t 2 /d R >nul\r
if errorlevel 2 goto :eof\r
goto CHECK_DEVICES\r
\r
:: ===============================================================================================\r
::  RESTORATION\r
:: ===============================================================================================\r
:RESTORE_SEQUENCE\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BG_GRN%  HYPEROS ESSENTIAL APP RESTORER                                                                                    %RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo.\r
echo  %TXT_GRN%[+] Device Connected. Beginning Full Restoration Sequence...%RESET%\r
echo.\r
\r
for %%a in (%ALL_APPS%) do (\r
    echo  %TXT_GRAY%Attempting to restore:%RESET% %TXT_WHT%%%a%RESET%\r
    if "!SIM_MODE!"=="1" (\r
        echo  %TXT_MAG%[DEBUG]%RESET% "!ADB_CMD!" -s !TARGET_ID! shell cmd package install-existing --user 0 %%a\r
        echo  %TXT_MAG%[DEBUG]%RESET% "!ADB_CMD!" -s !TARGET_ID! shell pm enable --user 0 %%a\r
    ) else (\r
        "!ADB_CMD!" -s !TARGET_ID! shell cmd package install-existing --user 0 %%a >nul 2>&1\r
        "!ADB_CMD!" -s !TARGET_ID! shell pm enable --user 0 %%a >nul 2>&1\r
    )\r
)\r
\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BG_GRN%  RESTORATION COMPLETE                                                                                              %RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo.\r
\r
if "!REBOOT_RESTORE!"=="1" (\r
    echo  %TXT_CYAN%Auto-Reboot is enabled. Rebooting device...%RESET%\r
    if "!SIM_MODE!"=="1" (\r
        echo  %TXT_MAG%[DEBUG]%RESET% "!ADB_CMD!" -s !TARGET_ID! reboot\r
    ) else (\r
        "!ADB_CMD!" -s !TARGET_ID! reboot\r
    )\r
) else (\r
    echo  %TXT_WHT%Please restart your device manually to ensure all system apps reinitialize properly.%RESET%\r
)\r
\r
echo.\r
pause\r
