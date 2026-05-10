@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=40
title Xiaomi HyperOS Restorer
cd /d "%~dp0"

:: Ensure ADB command is absolute if present in folder, else rely on PATH
set "ADB_CMD=adb"
if exist "%~dp0adb.exe" set "ADB_CMD="%~dp0adb.exe""

:: ANSI Colors Setup
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "BG_GRN=%ESC%[42m%ESC%[30m"
set "TXT_CYAN=%ESC%[96m"
set "TXT_GRN=%ESC%[92m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

:: Load shared configuration
call "%~dp0config.cmd"

:: Combine all packages from all phases
set "ALL_APPS=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only% com.xiaomi.joyose"

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
    
    :: Install-existing recovers uninstalled apps for User 0
    !ADB_CMD! shell cmd package install-existing --user 0 %%a >nul 2>&1
    
    :: Enable unfreezes apps that were disabled
    !ADB_CMD! shell pm enable --user 0 %%a >nul 2>&1
)

echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_GRN%  RESTORATION COMPLETE                                                                                              %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_WHT%Please restart your device to ensure all system apps reinitialize properly.%RESET%
echo.
echo  Press any key to return...
pause >nul
goto :eof