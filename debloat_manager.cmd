@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=40
title Xiaomi HyperOS Debloat Manager

:: Safely define paths from the root directory
cd /d "%~dp0"
set "ROOT_DIR=%cd%"
set "CONFIG_PATH=%cd%\data\config\config.json"
set "CONFIG_DEFAULT_PATH=%cd%\data\config\config_default.json"
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
set "TXT_MAG=%ESC%[95m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

:: Auto-recover missing config by cloning the default
if not exist "%CONFIG_PATH%" (
    if not exist "%cd%\data\config" mkdir "%cd%\data\config"
    call :RESTORE_DEFAULTS_SILENT
)

:MAIN_MENU
:: Fetch Joyose setting safely via file creation method
set "TEMP_MGR_VARS=%temp%\hyperos_mgr_init_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; 'set JOYOSE_ACTION=' + $c.settings.joyoseAction" > "%TEMP_MGR_VARS%"
call "%TEMP_MGR_VARS%"
del "%TEMP_MGR_VARS%"

cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT MANAGER %TXT_CYAN%-%TXT_WHT% Master Dashboard%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%[1]%RESET% Start Debloater %TXT_GRAY%(data\code\debloat_hyperos.bat)%RESET%
echo  %TXT_GRAY%Launch the interactive tool to safely remove or freeze bloatware.%RESET%
echo.
echo  %TXT_GRN%[2]%RESET% Start Full Restorer %TXT_GRAY%(data\code\debloat_restore.bat)%RESET%
echo  %TXT_GRAY%Recover all standard, advanced, risky, and hidden apps from the config database.%RESET%
echo.
echo  %TXT_YEL%[3]%RESET% Manage Joyose Policy %TXT_GRAY%(Current Setting: !JOYOSE_ACTION!)%RESET%
echo  %TXT_GRAY%Configure how the script handles com.xiaomi.joyose (Thermal Management).%RESET%
echo.
echo  %TXT_MAG%[4]%RESET% Advanced Config Settings
echo  %TXT_GRAY%Toggle smart filtering, simulation mode, uninstallation methods, and more.%RESET%
echo.
echo  %TXT_RED%[E]%RESET% Exit
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Press %TXT_CYAN%[1]%RESET%, %TXT_GRN%[2]%RESET%, %TXT_YEL%[3]%RESET%, %TXT_MAG%[4]%RESET%, or %TXT_RED%[E]%RESET% Exit...

choice /c 1234E /n >nul
if errorlevel 5 exit
if errorlevel 4 goto CONFIG_ADVANCED_INIT
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
echo  %BOLD%%TXT_WHT%  JOYOSE POLICY CONFIGURATION%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%

echo.
echo  %TXT_YEL%WARNING:%RESET% 
echo  %TXT_GRAY%The Joyose package is really weird service. Disabling it may cause unexpected behavior in the system.
echo  %TXT_GRAY%Disabling it may enhance the overall performance or cause severe thermal throttling under heavy load.
echo  %TXT_GRAY%It is recommended to treat it with caution and only disable it if you know what you're doing.%RESET%
echo.
echo  How should the Debloater handle Joyose?
echo  %TXT_CYAN%[A]%RESET% Ask me every time about it %TXT_GRAY%(Recommended)%RESET%
echo  %TXT_MAG%[R]%RESET% Automatically remove it always %TXT_GRAY%(Expert)%RESET%
echo  %TXT_GRN%[K]%RESET% Keep it installed and do not touch it %TXT_GRAY%(Safest)%RESET%
echo.
echo  %TXT_RED%[E] %TXT_RED%[Exit]%RESET% without saving any changes...%RESET%
echo.
choice /c ARKE /n >nul
if errorlevel 4 goto MAIN_MENU
if errorlevel 3 set "NEW_JOYOSE=KEEP"
if errorlevel 2 set "NEW_JOYOSE=REMOVE"
if errorlevel 1 set "NEW_JOYOSE=ASK"

powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $c.settings.joyoseAction = '%NEW_JOYOSE%'; $c | ConvertTo-Json -Depth 5 | Set-Content '%CONFIG_PATH%'"
echo.
echo  %TXT_GRN%[v] JSON Configuration updated.%RESET%
timeout /t 2 >nul
goto MAIN_MENU

:CONFIG_ADVANCED_INIT
set "CHANGES_MADE=0"
:: Fetch current boolean settings into memory
set "TEMP_MGR_VARS=%temp%\hyperos_mgr_vars_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; 'set V_SMART=' + [int][bool]$c.settings.smartFiltering; 'set V_PREVIEW=' + [int][bool]$c.settings.showPreview; 'set V_LOG=' + [int][bool]$c.settings.logToText; 'set V_DIS=' + [int][bool]$c.settings.disableInsteadOfUninstall; 'set V_REBOOT=' + [int][bool]$c.settings.rebootAfterRestore; 'set V_CORE=' + [int][bool]$c.settings.skipSystemCore; 'set V_ADB=' + [int][bool]$c.settings.forceADBRestart; 'set V_SIM=' + [int][bool]$c.settings.simulationMode" > "%TEMP_MGR_VARS%"
call "%TEMP_MGR_VARS%"
del "%TEMP_MGR_VARS%"

:CONFIG_ADVANCED
if "!V_SMART!"=="1" (set "D_SMART=%TXT_GRN%ON %RESET%") else (set "D_SMART=%TXT_RED%OFF%RESET%")
if "!V_PREVIEW!"=="1" (set "D_PREVIEW=%TXT_GRN%ON %RESET%") else (set "D_PREVIEW=%TXT_RED%OFF%RESET%")
if "!V_LOG!"=="1" (set "D_LOG=%TXT_GRN%ON %RESET%") else (set "D_LOG=%TXT_RED%OFF%RESET%")
if "!V_DIS!"=="1" (set "D_DIS=%TXT_GRN%ON %RESET%") else (set "D_DIS=%TXT_RED%OFF%RESET%")
if "!V_REBOOT!"=="1" (set "D_REBOOT=%TXT_GRN%ON %RESET%") else (set "D_REBOOT=%TXT_RED%OFF%RESET%")
if "!V_CORE!"=="1" (set "D_CORE=%TXT_GRN%ON %RESET%") else (set "D_CORE=%TXT_RED%OFF%RESET%")
if "!V_ADB!"=="1" (set "D_ADB=%TXT_GRN%ON %RESET%") else (set "D_ADB=%TXT_RED%OFF%RESET%")
if "!V_SIM!"=="1" (set "D_SIM=%TXT_GRN%ON %RESET%") else (set "D_SIM=%TXT_RED%OFF%RESET%")

cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  ADVANCED SETTINGS CONFIGURATION%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
if "!CHANGES_MADE!"=="1" echo  %BG_YEL%  [!] You have unsaved modifications. Press [S] to save them.                                        %RESET%
echo.
echo  %TXT_CYAN%[1]%RESET% Smart Filtering             [%D_SMART%] %TXT_GRAY%(Auto-skips apps already in target state)%RESET%
echo  %TXT_CYAN%[2]%RESET% Show Previews               [%D_PREVIEW%] %TXT_GRAY%(Displays lists before running phases)%RESET%
echo  %TXT_CYAN%[3]%RESET% Log to Text File            [%D_LOG%] %TXT_GRAY%(Saves debloat logs to /logs folder)%RESET%
echo  %TXT_YEL%[4]%RESET% Freeze instead of Uninstall [%D_DIS%] %TXT_GRAY%(Uses 'pm disable-user' instead of 'uninstall -k')%RESET%
echo  %TXT_YEL%[5]%RESET% Auto-Reboot after Restore   [%D_REBOOT%] %TXT_GRAY%(Reboots device automatically when Restorer finishes)%RESET%
echo  %TXT_YEL%[6]%RESET% Protect Core System Apps    [%D_CORE%] %TXT_GRAY%(Automatically skips Phase 3 Risky Apps)%RESET%
echo  %TXT_YEL%[7]%RESET% Force ADB Restart on Boot   [%D_ADB%] %TXT_GRAY%(Kills and restarts ADB server upon script launch)%RESET%
echo.
echo  %TXT_GRAY%--- [DEBUG / DEVELOPMENT] ------------------------------------------------------------------------------------------%RESET%
echo  %TXT_MAG%[8]%RESET% [DEBUG] Simulation Mode     [%D_SIM%] %TXT_GRAY%(Prints ADB commands without running them to test logic)%RESET%
echo.
echo  %TXT_GRAY%--- [SETTINGS] -----------------------------------------------------------------------------------------------------%RESET%
echo  %TXT_GRN%[S]%RESET% Save Modified Settings
echo  %TXT_CYAN%[D]%RESET% Restore Default Settings
echo.
echo  %TXT_GRAY%--- [MENU] ---------------------------------------------------------------------------------------------------------%RESET%
echo  %TXT_RED%[E]%RESET% %TXT_RED%[Exit]%RESET% to Main Menu...
echo.
choice /c 12345678SDE /n >nul
if errorlevel 11 goto EXIT_ADVANCED
if errorlevel 10 goto RESTORE_DEFAULTS_INTERACTIVE
if errorlevel 9 goto SAVE_SETTINGS_INTERACTIVE
if errorlevel 8 call :TOGGLE_MEM V_SIM
if errorlevel 7 call :TOGGLE_MEM V_ADB
if errorlevel 6 call :TOGGLE_MEM V_CORE
if errorlevel 5 call :TOGGLE_MEM V_REBOOT
if errorlevel 4 call :TOGGLE_MEM V_DIS
if errorlevel 3 call :TOGGLE_MEM V_LOG
if errorlevel 2 call :TOGGLE_MEM V_PREVIEW
if errorlevel 1 call :TOGGLE_MEM V_SMART
goto CONFIG_ADVANCED

:TOGGLE_MEM
if "!%~1!"=="1" (set "%~1=0") else (set "%~1=1")
set "CHANGES_MADE=1"
goto :eof

:SAVE_SETTINGS_INTERACTIVE
call :SAVE_SETTINGS_SILENT
echo.
echo  %TXT_GRN%[v] Settings saved successfully.%RESET%
timeout /t 2 >nul
goto CONFIG_ADVANCED

:SAVE_SETTINGS_SILENT
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $c.settings.smartFiltering = [bool]!V_SMART!; $c.settings.showPreview = [bool]!V_PREVIEW!; $c.settings.logToText = [bool]!V_LOG!; $c.settings.disableInsteadOfUninstall = [bool]!V_DIS!; $c.settings.rebootAfterRestore = [bool]!V_REBOOT!; $c.settings.skipSystemCore = [bool]!V_CORE!; $c.settings.forceADBRestart = [bool]!V_ADB!; $c.settings.simulationMode = [bool]!V_SIM!; $c | ConvertTo-Json -Depth 5 | Set-Content '%CONFIG_PATH%'"
set "CHANGES_MADE=0"
goto :eof

:EXIT_ADVANCED
if "!CHANGES_MADE!"=="1" (
    echo.
    echo  %TXT_YEL%[!] You have unsaved changes.%RESET%
    echo  Do you want to save them before exiting?
    echo  %TXT_GRN%[Y]%RESET%es, save   %TXT_RED%[N]%RESET%o, discard   %TXT_GRAY%[C]%RESET%ancel exit
    choice /c YNC /n >nul
    if errorlevel 3 goto CONFIG_ADVANCED
    if errorlevel 2 goto MAIN_MENU
    if errorlevel 1 (
        call :SAVE_SETTINGS_SILENT
        goto MAIN_MENU
    )
)
goto MAIN_MENU

:RESTORE_DEFAULTS_INTERACTIVE
echo.
echo  %TXT_YEL%WARNING: Are you sure you want to restore all Advanced Settings to their defaults?%RESET%
echo  %TXT_RED%[Y]%RESET%es, restore   %TXT_GRAY%[N]%RESET%o, cancel
choice /c YN /n >nul
if errorlevel 2 goto CONFIG_ADVANCED

call :RESTORE_DEFAULTS_SILENT
echo.
echo  %TXT_GRN%[v] Default settings restored successfully.%RESET%
timeout /t 2 >nul
goto CONFIG_ADVANCED_INIT

:RESTORE_DEFAULTS_SILENT
:: Clone default file over the active config
copy /Y "%CONFIG_DEFAULT_PATH%" "%CONFIG_PATH%" >nul
goto :eof