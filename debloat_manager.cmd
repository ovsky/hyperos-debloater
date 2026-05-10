@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=40
title Xiaomi HyperOS Debloat Manager

:: Safely define paths from the root directory
cd /d "%~dp0"
set "ROOT_DIR=%cd%"
set "CONFIG_PATH=%cd%\data\config\config.json"
set "CODE_DIR=%cd%\data\code"

:: ANSI Colors Setup
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "BG_CYAN=%ESC%[46m%ESC%[30m"
set "TXT_CYAN=%ESC%[96m"
set "TXT_GRN=%ESC%[92m"
set "TXT_YEL=%ESC%[93m"
set "TXT_RED=%ESC%[91m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

if not exist "%CONFIG_PATH%" (
    echo [!] ERROR: "%CONFIG_PATH%" is missing. 
    pause & exit
)

:MAIN_MENU
:: Read Joyose Action from JSON via PowerShell
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json).settings.joyoseAction"') do set "JOYOSE_ACTION=%%A"

cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT MANAGER %TXT_CYAN%-%TXT_WHT% Master Dashboard%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%[1]%RESET% Start Debloater %TXT_GRAY%(data\code\debloat_hyperos.bat)%RESET%
echo      Launch the interactive tool to safely remove or freeze bloatware.
echo.
echo  %TXT_GRN%[2]%RESET% Start Full Restorer %TXT_GRAY%(data\code\debloat_restore.bat)%RESET%
echo      Recover all standard, advanced, risky, and hidden apps from the config database.
echo.
echo  %TXT_YEL%[3]%RESET% Manage Joyose Policy %TXT_GRAY%(Current Setting: !JOYOSE_ACTION!)%RESET%
echo      Configure how the script handles com.xiaomi.joyose (Thermal Management).
echo.
echo  %TXT_MAG%[4]%RESET% Advanced Config Settings
echo      Toggle smart filtering, simulation mode, uninstallation methods, and more.
echo.
echo  %TXT_RED%[E]%RESET%xit
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Press %TXT_CYAN%[1]%RESET%, %TXT_GRN%[2]%RESET%, %TXT_YEL%[3]%RESET%, %TXT_MAG%[4]%RESET%, or %TXT_RED%[E]%RESET%xit...

choice /c 1234E /n >nul
if errorlevel 5 exit
if errorlevel 4 goto CONFIG_ADVANCED
if errorlevel 3 goto CONFIG_JOYOSE
if errorlevel 2 (
    call "%CODE_DIR%\debloat_restore.bat"
    goto MAIN_MENU
)
if errorlevel 1 (
    call "%CODE_DIR%\debloat_hyperos.bat"
    goto MAIN_MENU
)

:CONFIG_JOYOSE
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  JOYOSE THERMAL MANAGEMENT CONFIGURATION%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  The %TXT_WHT%com.xiaomi.joyose%RESET% app manages thermal components in the system.
echo  %TXT_YEL%WARNING:%RESET% It may be required in low-end and mid-end devices to prevent overheating.
echo  If you want to turn it off, do it wisely to avoid thermal throttling.
echo.
echo  How should the Debloater handle Joyose?
echo  %TXT_CYAN%[A]%RESET% Ask me every time I run the Debloater
echo  %TXT_RED%[R]%RESET% Automatically include it in the Debloat queue (Phase 1)
echo  %TXT_GRN%[K]%RESET% Keep it safe (Never debloat it)
echo  %TXT_GRAY%[E] Exit without saving changes%RESET%
echo.
choice /c ARKE /n >nul
if errorlevel 4 goto MAIN_MENU
if errorlevel 3 set "NEW_JOYOSE=KEEP"
if errorlevel 2 set "NEW_JOYOSE=REMOVE"
if errorlevel 1 set "NEW_JOYOSE=ASK"

:: Write change to JSON using PowerShell
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $c.settings.joyoseAction = '%NEW_JOYOSE%'; $c | ConvertTo-Json -Depth 5 | Set-Content '%CONFIG_PATH%'"

echo.
echo  %TXT_GRN%[v] JSON Configuration updated.%RESET%
timeout /t 2 >nul
goto MAIN_MENU

:CONFIG_ADVANCED
:: Fetch current boolean settings using the secure Temp File method
set "TEMP_MGR_VARS=%temp%\hyperos_mgr_vars_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $out = @(); $out += 'set \"V_SMART=' + [int][bool]$c.settings.smartFiltering + '\"'; $out += 'set \"V_PREVIEW=' + [int][bool]$c.settings.showPreview + '\"'; $out += 'set \"V_LOG=' + [int][bool]$c.settings.logToText + '\"'; $out += 'set \"V_SIM=' + [int][bool]$c.settings.simulationMode + '\"'; $out += 'set \"V_DIS=' + [int][bool]$c.settings.disableInsteadOfUninstall + '\"'; $out += 'set \"V_REBOOT=' + [int][bool]$c.settings.rebootAfterRestore + '\"'; $out | Set-Content -Path '%TEMP_MGR_VARS%' -Encoding ASCII"
call "%TEMP_MGR_VARS%"
del "%TEMP_MGR_VARS%"

if "!V_SMART!"=="1" (set "D_SMART=%TXT_GRN%ON %RESET%") else (set "D_SMART=%TXT_RED%OFF%RESET%")
if "!V_PREVIEW!"=="1" (set "D_PREVIEW=%TXT_GRN%ON %RESET%") else (set "D_PREVIEW=%TXT_RED%OFF%RESET%")
if "!V_LOG!"=="1" (set "D_LOG=%TXT_GRN%ON %RESET%") else (set "D_LOG=%TXT_RED%OFF%RESET%")
if "!V_SIM!"=="1" (set "D_SIM=%TXT_GRN%ON %RESET%") else (set "D_SIM=%TXT_RED%OFF%RESET%")
if "!V_DIS!"=="1" (set "D_DIS=%TXT_GRN%ON %RESET%") else (set "D_DIS=%TXT_RED%OFF%RESET%")
if "!V_REBOOT!"=="1" (set "D_REBOOT=%TXT_GRN%ON %RESET%") else (set "D_REBOOT=%TXT_RED%OFF%RESET%")

cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  ADVANCED SETTINGS CONFIGURATION%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%[1]%RESET% Smart Filtering             [%D_SMART%] %TXT_GRAY%(Auto-skips apps already in target state)%RESET%
echo  %TXT_CYAN%[2]%RESET% Show Previews               [%D_PREVIEW%] %TXT_GRAY%(Displays lists before running phases)%RESET%
echo  %TXT_CYAN%[3]%RESET% Log to Text File            [%D_LOG%] %TXT_GRAY%(Saves debloat logs to /logs folder)%RESET%
echo  %TXT_YEL%[4]%RESET% Simulation Mode             [%D_SIM%] %TXT_GRAY%(Prints ADB commands without running them)%RESET%
echo  %TXT_YEL%[5]%RESET% Freeze instead of Uninstall [%D_DIS%] %TXT_GRAY%(Uses 'pm disable-user' instead of 'uninstall -k')%RESET%
echo  %TXT_YEL%[6]%RESET% Auto-Reboot after Restore   [%D_REBOOT%] %TXT_GRAY%(Reboots device automatically when Restorer finishes)%RESET%
echo.
echo  %TXT_RED%[E]%RESET% Back to Main Menu
echo.
choice /c 123456E /n >nul
if errorlevel 7 goto MAIN_MENU
if errorlevel 6 call :TOGGLE_BOOL rebootAfterRestore
if errorlevel 5 call :TOGGLE_BOOL disableInsteadOfUninstall
if errorlevel 4 call :TOGGLE_BOOL simulationMode
if errorlevel 3 call :TOGGLE_BOOL logToText
if errorlevel 2 call :TOGGLE_BOOL showPreview
if errorlevel 1 call :TOGGLE_BOOL smartFiltering
goto CONFIG_ADVANCED

:TOGGLE_BOOL
set "JSON_KEY=%~1"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $c.settings.%JSON_KEY% = -not $c.settings.%JSON_KEY%; $c | ConvertTo-Json -Depth 5 | Set-Content '%CONFIG_PATH%'"
goto :eof