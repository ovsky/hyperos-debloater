@echo off\r
setlocal EnableDelayedExpansion\r
mode con: cols=120 lines=40\r
title Xiaomi HyperOS Debloat Manager\r
\r
:: Safely define paths from the root directory\r
cd /d "%~dp0"\r
set "ROOT_DIR=%cd%"\r
set "CONFIG_PATH=%cd%\data\config\config.json"\r
set "CONFIG_DEFAULT_PATH=%cd%\data\config\config_default.json"\r
set "CODE_DIR=%cd%\data\code"\r
\r
:: ANSI Colors Setup\r
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"\r
set "RESET=%ESC%[0m"\r
set "BOLD=%ESC%[1m"\r
set "BG_CYAN=%ESC%[46m%ESC%[30m"\r
set "TXT_CYAN=%ESC%[96m"\r
set "TXT_GRN=%ESC%[92m"\r
set "TXT_YEL=%ESC%[93m"\r
set "TXT_RED=%ESC%[91m"\r
set "TXT_MAG=%ESC%[95m"\r
set "TXT_GRAY=%ESC%[90m"\r
set "TXT_WHT=%ESC%[97m"\r
\r
:: Auto-recover missing config by cloning the default\r
if not exist "%CONFIG_PATH%" (\r
    if not exist "%cd%\data\config" mkdir "%cd%\data\config"\r
    call :RESTORE_DEFAULTS_SILENT\r
)\r
\r
:MAIN_MENU\r
:: Fetch Joyose setting safely via file creation method\r
set "TEMP_MGR_VARS=%temp%\hyperos_mgr_init_%RANDOM%.cmd"\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; 'set JOYOSE_ACTION=' + $c.settings.joyoseAction" > "%TEMP_MGR_VARS%"\r
call "%TEMP_MGR_VARS%"\r
del "%TEMP_MGR_VARS%"\r
\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT MANAGER %TXT_CYAN%-%TXT_WHT% Master Dashboard%RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo.\r
echo  %TXT_CYAN%[1]%RESET% Start Debloater %TXT_GRAY%(data\code\debloat_hyperos.bat)%RESET%\r
echo  %TXT_GRAY%Launch the interactive tool to safely remove or freeze bloatware.%RESET%\r
echo.\r
echo  %TXT_GRN%[2]%RESET% Start Full Restorer %TXT_GRAY%(data\code\debloat_restore.bat)%RESET%\r
echo  %TXT_GRAY%Recover all standard, advanced, risky, and hidden apps from the config database.%RESET%\r
echo.\r
echo  %TXT_YEL%[3]%RESET% Manage Joyose Policy %TXT_GRAY%(Current Setting: !JOYOSE_ACTION!)%RESET%\r
echo  %TXT_GRAY%Configure how the script handles com.xiaomi.joyose (Thermal Management).%RESET%\r
echo.\r
echo  %TXT_MAG%[4]%RESET% Advanced Config Settings\r
echo  %TXT_GRAY%Toggle smart filtering, simulation mode, uninstallation methods, and more.%RESET%\r
echo.\r
echo  %TXT_RED%[E]%RESET% Exit\r
echo.\r
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%\r
echo  Press %TXT_CYAN%[1]%RESET%, %TXT_GRN%[2]%RESET%, %TXT_YEL%[3]%RESET%, %TXT_MAG%[4]%RESET%, or %TXT_RED%[E]%RESET% Exit...\r
\r
choice /c 1234E /n >nul\r
if errorlevel 5 exit\r
if errorlevel 4 goto CONFIG_ADVANCED_INIT\r
if errorlevel 3 goto CONFIG_JOYOSE\r
if errorlevel 2 (\r
    call "%CODE_DIR%\debloat_restore.bat"\r
    goto MAIN_MENU\r
)\r
if errorlevel 1 (\r
    call "%CODE_DIR%\debloat_hyperos.bat"\r
    goto MAIN_MENU\r
)\r
\r
:CONFIG_JOYOSE\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%%TXT_WHT%  JOYOSE POLICY CONFIGURATION%RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
\r
echo.\r
echo  %TXT_YEL%WARNING:%RESET% \r
echo  %TXT_GRAY%The Joyose package is really weird service. Disabling it may cause unexpected behavior in the system.\r
echo  %TXT_GRAY%Disabling it may enhance the overall performance or cause severe thermal throttling under heavy load.\r
echo  %TXT_GRAY%It is recommended to treat it with caution and only disable it if you know what you're doing.%RESET%\r
echo.\r
echo  How should the Debloater handle Joyose?\r
echo  %TXT_CYAN%[A]%RESET% Ask me every time about it %TXT_GRAY%(Recommended)%RESET%\r
echo  %TXT_MAG%[R]%RESET% Automatically remove it always %TXT_GRAY%(Expert)%RESET%\r
echo  %TXT_GRN%[K]%RESET% Keep it installed and do not touch it %TXT_GRAY%(Safest)%RESET%\r
echo.\r
echo  %TXT_RED%[E] %TXT_RED%[Exit]%RESET% without saving any changes...%RESET%\r
echo.\r
choice /c ARKE /n >nul\r
if errorlevel 4 goto MAIN_MENU\r
if errorlevel 3 set "NEW_JOYOSE=KEEP"\r
if errorlevel 2 set "NEW_JOYOSE=REMOVE"\r
if errorlevel 1 set "NEW_JOYOSE=ASK"\r
\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $c.settings.joyoseAction = '%NEW_JOYOSE%'; $c | ConvertTo-Json -Depth 5 | Set-Content '%CONFIG_PATH%'"\r
echo.\r
echo  %TXT_GRN%[v] JSON Configuration updated.%RESET%\r
timeout /t 2 >nul\r
goto MAIN_MENU\r
\r
:CONFIG_ADVANCED_INIT\r
set "CHANGES_MADE=0"\r
:: Fetch current boolean settings into memory\r
set "TEMP_MGR_VARS=%temp%\hyperos_mgr_vars_%RANDOM%.cmd"\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; 'set V_SMART=' + [int][bool]$c.settings.smartFiltering; 'set V_PREVIEW=' + [int][bool]$c.settings.showPreview; 'set V_LOG=' + [int][bool]$c.settings.logToText; 'set V_DIS=' + [int][bool]$c.settings.disableInsteadOfUninstall; 'set V_REBOOT=' + [int][bool]$c.settings.rebootAfterRestore; 'set V_CORE=' + [int][bool]$c.settings.skipSystemCore; 'set V_ADB=' + [int][bool]$c.settings.forceADBRestart; 'set V_SIM=' + [int][bool]$c.settings.simulationMode" > "%TEMP_MGR_VARS%"\r
call "%TEMP_MGR_VARS%"\r
del "%TEMP_MGR_VARS%"\r
\r
:CONFIG_ADVANCED\r
if "!V_SMART!"=="1" (set "D_SMART=%TXT_GRN%ON %RESET%") else (set "D_SMART=%TXT_RED%OFF%RESET%")\r
if "!V_PREVIEW!"=="1" (set "D_PREVIEW=%TXT_GRN%ON %RESET%") else (set "D_PREVIEW=%TXT_RED%OFF%RESET%")\r
if "!V_LOG!"=="1" (set "D_LOG=%TXT_GRN%ON %RESET%") else (set "D_LOG=%TXT_RED%OFF%RESET%")\r
if "!V_DIS!"=="1" (set "D_DIS=%TXT_GRN%ON %RESET%") else (set "D_DIS=%TXT_RED%OFF%RESET%")\r
if "!V_REBOOT!"=="1" (set "D_REBOOT=%TXT_GRN%ON %RESET%") else (set "D_REBOOT=%TXT_RED%OFF%RESET%")\r
if "!V_CORE!"=="1" (set "D_CORE=%TXT_GRN%ON %RESET%") else (set "D_CORE=%TXT_RED%OFF%RESET%")\r
if "!V_ADB!"=="1" (set "D_ADB=%TXT_GRN%ON %RESET%") else (set "D_ADB=%TXT_RED%OFF%RESET%")\r
if "!V_SIM!"=="1" (set "D_SIM=%TXT_GRN%ON %RESET%") else (set "D_SIM=%TXT_RED%OFF%RESET%")\r
\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%%TXT_WHT%  ADVANCED SETTINGS CONFIGURATION%RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
if "!CHANGES_MADE!"=="1" echo  %BG_YEL%  [!] You have unsaved modifications. Press [S] to save them.                                        %RESET%\r
echo.\r
echo  %TXT_CYAN%[1]%RESET% Smart Filtering             [%D_SMART%] %TXT_GRAY%(Auto-skips apps already in target state)%RESET%\r
echo  %TXT_CYAN%[2]%RESET% Show Previews               [%D_PREVIEW%] %TXT_GRAY%(Displays lists before running phases)%RESET%\r
echo  %TXT_CYAN%[3]%RESET% Log to Text File            [%D_LOG%] %TXT_GRAY%(Saves debloat logs to /logs folder)%RESET%\r
echo  %TXT_YEL%[4]%RESET% Freeze instead of Uninstall [%D_DIS%] %TXT_GRAY%(Uses 'pm disable-user' instead of 'uninstall -k')%RESET%\r
echo  %TXT_YEL%[5]%RESET% Auto-Reboot after Restore   [%D_REBOOT%] %TXT_GRAY%(Reboots device automatically when Restorer finishes)%RESET%\r
echo  %TXT_YEL%[6]%RESET% Protect Core System Apps    [%D_CORE%] %TXT_GRAY%(Automatically skips Phase 3 Risky Apps)%RESET%\r
echo  %TXT_YEL%[7]%RESET% Force ADB Restart on Boot   [%D_ADB%] %TXT_GRAY%(Kills and restarts ADB server upon script launch)%RESET%\r
echo.\r
echo  %TXT_GRAY%--- [DEBUG / DEVELOPMENT] ------------------------------------------------------------------------------------------%RESET%\r
echo  %TXT_MAG%[8]%RESET% [DEBUG] Simulation Mode     [%D_SIM%] %TXT_GRAY%(Prints ADB commands without running them to test logic)%RESET%\r
echo.\r
echo  %TXT_GRAY%--- [SETTINGS] -----------------------------------------------------------------------------------------------------%RESET%\r
echo  %TXT_GRN%[S]%RESET% Save Modified Settings\r
echo  %TXT_CYAN%[D]%RESET% Restore Default Settings\r
echo.\r
echo  %TXT_GRAY%--- [MENU] ---------------------------------------------------------------------------------------------------------%RESET%\r
echo  %TXT_RED%[E]%RESET% %TXT_RED%[Exit]%RESET% to Main Menu...\r
echo.\r
choice /c 12345678SDE /n >nul\r
if errorlevel 11 goto EXIT_ADVANCED\r
if errorlevel 10 goto RESTORE_DEFAULTS_INTERACTIVE\r
if errorlevel 9 goto SAVE_SETTINGS_INTERACTIVE\r
if errorlevel 8 call :TOGGLE_MEM V_SIM\r
if errorlevel 7 call :TOGGLE_MEM V_ADB\r
if errorlevel 6 call :TOGGLE_MEM V_CORE\r
if errorlevel 5 call :TOGGLE_MEM V_REBOOT\r
if errorlevel 4 call :TOGGLE_MEM V_DIS\r
if errorlevel 3 call :TOGGLE_MEM V_LOG\r
if errorlevel 2 call :TOGGLE_MEM V_PREVIEW\r
if errorlevel 1 call :TOGGLE_MEM V_SMART\r
goto CONFIG_ADVANCED\r
\r
:TOGGLE_MEM\r
if "!%~1!"=="1" (set "%~1=0") else (set "%~1=1")\r
set "CHANGES_MADE=1"\r
goto :eof\r
\r
:SAVE_SETTINGS_INTERACTIVE\r
call :SAVE_SETTINGS_SILENT\r
echo.\r
echo  %TXT_GRN%[v] Settings saved successfully.%RESET%\r
timeout /t 2 >nul\r
goto CONFIG_ADVANCED\r
\r
:SAVE_SETTINGS_SILENT\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $c.settings.smartFiltering = [bool]!V_SMART!; $c.settings.showPreview = [bool]!V_PREVIEW!; $c.settings.logToText = [bool]!V_LOG!; $c.settings.disableInsteadOfUninstall = [bool]!V_DIS!; $c.settings.rebootAfterRestore = [bool]!V_REBOOT!; $c.settings.skipSystemCore = [bool]!V_CORE!; $c.settings.forceADBRestart = [bool]!V_ADB!; $c.settings.simulationMode = [bool]!V_SIM!; $c | ConvertTo-Json -Depth 5 | Set-Content '%CONFIG_PATH%'"\r
set "CHANGES_MADE=0"\r
goto :eof\r
\r
:EXIT_ADVANCED\r
if "!CHANGES_MADE!"=="1" (\r
    echo.\r
    echo  %TXT_YEL%[!] You have unsaved changes.%RESET%\r
    echo  Do you want to save them before exiting?\r
    echo  %TXT_GRN%[Y]%RESET%es, save   %TXT_RED%[N]%RESET%o, discard   %TXT_GRAY%[C]%RESET%ancel exit\r
    choice /c YNC /n >nul\r
    if errorlevel 3 goto CONFIG_ADVANCED\r
    if errorlevel 2 goto MAIN_MENU\r
    if errorlevel 1 (\r
        call :SAVE_SETTINGS_SILENT\r
        goto MAIN_MENU\r
    )\r
)\r
goto MAIN_MENU\r
\r
:RESTORE_DEFAULTS_INTERACTIVE\r
echo.\r
echo  %TXT_YEL%WARNING: Are you sure you want to restore all Advanced Settings to their defaults?%RESET%\r
echo  %TXT_RED%[Y]%RESET%es, restore   %TXT_GRAY%[N]%RESET%o, cancel\r
choice /c YN /n >nul\r
if errorlevel 2 goto CONFIG_ADVANCED\r
\r
call :RESTORE_DEFAULTS_SILENT\r
echo.\r
echo  %TXT_GRN%[v] Default settings restored successfully.%RESET%\r
timeout /t 2 >nul\r
goto CONFIG_ADVANCED_INIT\r
\r
:RESTORE_DEFAULTS_SILENT\r
:: Clone default file over the active config\r
copy /Y "%CONFIG_DEFAULT_PATH%" "%CONFIG_PATH%" >nul\r
goto :eof\r
