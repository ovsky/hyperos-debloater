@echo off\r
setlocal EnableDelayedExpansion\r
mode con: cols=120 lines=50\r
title Xiaomi HyperOS Debloat Commander v17.9\r
\r
:: Secure absolute paths\r
for %%A in ("%~dp0..\..\") do set "ROOT_DIR=%%~fA"\r
set "CONFIG_PATH=%ROOT_DIR%\data\config\config.json"\r
set "SERVICES_PATH=%ROOT_DIR%\data\config\services.json"\r
set "LOGS_DIR=%ROOT_DIR%\logs"\r
\r
:: Validate JSON Integrity\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json" >nul 2>&1\r
if %errorlevel% neq 0 (\r
    echo [!] ERROR: One of your JSON files contains syntax errors or is missing.\r
    pause & exit\r
)\r
\r
:: Securely dump JSON variables directly into Batch\r
set "TEMP_VARS=%temp%\hyperos_vars_%RANDOM%.cmd"\r
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json; 'set JOYOSE_ACTION=' + $c.settings.joyoseAction; 'set SKIP_NOT_INSTALLED=' + [int][bool]$c.settings.smartFiltering; 'set SHOW_PREVIEW=' + [int][bool]$c.settings.showPreview; 'set LOG_ENABLED=' + [int][bool]$c.settings.logToText; 'set SIM_MODE=' + [int][bool]$c.settings.simulationMode; 'set DISABLE_MODE=' + [int][bool]$c.settings.disableInsteadOfUninstall; 'set PROTECT_CORE=' + [int][bool]$c.settings.skipSystemCore; 'set FORCE_ADB=' + [int][bool]$c.settings.forceADBRestart; 'set ADB_PATH=' + $c.settings.defaultAdbPath; 'set apps_p1=' + ($s.phases.phase1_safe -join ' '); 'set apps_p2=' + ($s.phases.phase2_advanced -join ' '); 'set apps_p3=' + ($s.phases.phase3_risky -join ' '); 'set apps_p4=' + ($s.phases.phase4_hidden -join ' '); 'set apps_restore_only=' + ($s.phases.restore_only -join ' '); $s.descriptions.PSObject.Properties | ForEach-Object { 'set DESC_' + $_.Name + '=' + $_.Value }" > "%TEMP_VARS%"\r
call "%TEMP_VARS%"\r
del "%TEMP_VARS%"\r
\r
:: Create immutable base copies\r
set "BASE_APPS_P1=%apps_p1%"\r
set "BASE_APPS_P4=%apps_p4%"\r
set "BASE_APPS_RESTORE_ONLY=%apps_restore_only%"\r
\r
:: ADB Setup\r
set "ADB_CMD=!ADB_PATH!"\r
if exist "%ROOT_DIR%\!ADB_PATH!" set "ADB_CMD=%ROOT_DIR%\!ADB_PATH!"\r
\r
:: ANSI Colors Setup\r
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"\r
set "RESET=%ESC%[0m"\r
set "BOLD=%ESC%[1m"\r
set "BG_CYAN=%ESC%[46m%ESC%[30m"\r
set "BG_MAG=%ESC%[45m%ESC%[30m"\r
set "BG_GRN=%ESC%[42m%ESC%[30m"\r
set "BG_YEL=%ESC%[43m%ESC%[30m"\r
set "BG_RED=%ESC%[41m%ESC%[97m"\r
set "TXT_CYAN=%ESC%[96m"\r
set "TXT_GRN=%ESC%[92m"\r
set "TXT_YEL=%ESC%[93m"\r
set "TXT_RED=%ESC%[91m"\r
set "TXT_MAG=%ESC%[95m"\r
set "TXT_GRAY=%ESC%[90m"\r
set "TXT_WHT=%ESC%[97m"\r
\r
:: Log File Setup\r
set "LOGFILE=NUL"\r
if "!LOG_ENABLED!"=="1" (\r
    if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"\r
    set "SAFE_DT=%DATE:/=-%"\r
    set "SAFE_DT=!SAFE_DT:\=-!"\r
    set "SAFE_DT=!SAFE_DT:.=-!"\r
    set "SAFE_TM=%TIME::=-%"\r
    set "SAFE_TM=!SAFE_TM:.=-!"\r
    set "SAFE_TM=!SAFE_TM: =0!"\r
    set "LOGFILE=%LOGS_DIR%\Debloat_Log_!SAFE_DT!_!SAFE_TM!.log"\r
    echo [LOG STARTED] > "!LOGFILE!"\r
    echo Target OS: Xiaomi HyperOS >> "!LOGFILE!"\r
    echo Date: %date% %time% >> "!LOGFILE!"\r
    echo -------------------------------------------------------- >> "!LOGFILE!"\r
)\r
\r
:: ADB Server Initialization\r
if "!FORCE_ADB!"=="1" (\r
    !ADB_CMD! kill-server >nul 2>&1\r
)\r
!ADB_CMD! start-server >nul 2>&1\r
\r
:: ===============================================================================================\r
::  AUTO-SCANNING DEVICE CONNECTION\r
:: ===============================================================================================\r
:CHECK_DEVICES\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT COMMANDER %TXT_CYAN%-%TXT_WHT% System Ready%RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
if "!SIM_MODE!"=="1" echo  %BG_YEL%  [DEBUG SIMULATION MODE ACTIVE] Commands will NOT be executed on the device!                        %RESET%\r
echo.\r
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                      %RESET%\r
echo  %TXT_GRAY%Auto-scanning for connected devices...\r
echo  %TXT_GRAY%Ensure USB Debugging is ON.%RESET%\r
echo.\r
echo  Press %TXT_RED%[E]%RESET% to cancel and return to Manager.\r
\r
set count=0\r
for /f "skip=1 tokens=1,2,*" %%a in ('!ADB_CMD! devices -l') do (\r
    if "%%b" == "device" (\r
        set /a count+=1\r
        set "device[!count!]=%%a"\r
        for /f "tokens=*" %%m in ('!ADB_CMD! -s %%a shell getprop ro.product.model') do set "model[!count!]=%%m"\r
    )\r
)\r
\r
if !count! GTR 0 (\r
    set "TARGET_ID=!device[1]!"\r
    set "TARGET_MODEL=!model[1]!"\r
    echo.\r
    echo  %TXT_GRN%  [v]%RESET% Connected Model: %TXT_WHT%!TARGET_MODEL!%RESET%\r
    timeout /t 2 >nul\r
    call :CACHE_DEVICE_STATE\r
    goto MAIN_MENU\r
)\r
\r
:: Wait 2 seconds, default to R (Retry), exit if user presses E\r
choice /c RE /n /t 2 /d R >nul\r
if errorlevel 2 goto :eof\r
goto CHECK_DEVICES\r
\r
:: ===============================================================================================\r
::  MAIN MENU\r
:: ===============================================================================================\r
:MAIN_MENU\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%%TXT_WHT%  MAIN MENU %TXT_CYAN%-%TXT_WHT% Select Functionality%RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo.\r
echo  %TXT_GRN%[1] Standard Debloat (Phases 1-4)%RESET%\r
echo  %TXT_CYAN%[2] Interactive App Explorer%RESET%\r
echo  %TXT_YEL%[3] Refresh Device Cache%RESET%\r
echo  %TXT_RED%[E] Return to Manager%RESET%\r
echo.\r
echo  Press %TXT_GRN%[1]%RESET%, %TXT_CYAN%[2]%RESET%, %TXT_YEL%[3]%RESET%, or %TXT_RED%[E]%RESET% Exit...\r
\r
choice /c 123E /n >nul\r
if errorlevel 4 goto :eof\r
if errorlevel 3 ( call :CACHE_DEVICE_STATE & goto MAIN_MENU )\r
if errorlevel 2 goto INTERACTIVE_EXPLORER_INIT\r
if errorlevel 1 goto MODE_SELECT\r
\r
:: ===============================================================================================\r
::  INTERACTIVE EXPLORER\r
:: ===============================================================================================\r
:INTERACTIVE_EXPLORER_INIT\r
set "SHOW_ACTIVE_ONLY=0"\r
set "all_db_apps=%apps_p1% %apps_p2% %apps_p3% %apps_p4% com.xiaomi.joyose"\r
\r
:EXPLORER_REBUILD_LIST\r
cls\r
if exist "%temp%\matched_apps.txt" del "%temp%\matched_apps.txt"\r
\r
for %%p in (!all_db_apps!) do (\r
    if "!SHOW_ACTIVE_ONLY!"=="1" (\r
        findstr /I /C:"package:%%p" "%temp%\adb_active.txt" >nul 2>&1\r
    ) else (\r
        findstr /I /C:"package:%%p" "%temp%\adb_all.txt" >nul 2>&1\r
    )\r
    if !errorlevel! equ 0 (\r
        call :GET_APP_NAME %%p\r
        echo !APP_LABEL!^|%%p>> "%temp%\matched_apps.txt"\r
    )\r
)\r
\r
set "total_apps=0"\r
if exist "%temp%\matched_apps.txt" (\r
    for /f "tokens=1,2 delims=|" %%A in ('sort "%temp%\matched_apps.txt"') do (\r
        set /a total_apps+=1\r
        set "app_list[!total_apps!]=%%A ^(%%B^)"\r
        set "app_pkg[!total_apps!]=%%B"\r
    )\r
    del "%temp%\matched_apps.txt" >nul 2>&1\r
)\r
\r
if !total_apps!==0 (\r
    echo  %TXT_RED%[!] No apps found for the current filter.%RESET%\r
    pause\r
    goto MAIN_MENU\r
)\r
set "current_index=1"\r
set "window_size=25"\r
\r
:EXPLORER_RENDER\r
cls\r
echo  %BG_CYAN%  INTERACTIVE APP EXPLORER ^| App !current_index! of !total_apps!                                                                  %RESET%\r
echo.\r
set /a half_window=window_size / 2\r
set /a start_idx=current_index - half_window\r
if !start_idx! LSS 1 set start_idx=1\r
set /a end_idx=start_idx + window_size - 1\r
if !end_idx! GTR !total_apps! (\r
    set end_idx=!total_apps!\r
    set /a start_idx=end_idx - window_size + 1\r
    if !start_idx! LSS 1 set start_idx=1\r
)\r
\r
for /L %%i in (!start_idx!,1,!end_idx!) do (\r
    if %%i==!current_index! ( echo   %BG_CYAN%%TXT_WHT% ^> !app_list[%%i]! %RESET% ) else ( echo      !app_list[%%i]! )\r
)\r
echo.\r
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%\r
echo  Controls: %TXT_GRN%[W]%RESET% Up  %TXT_GRN%[S]%RESET% Down  %TXT_YEL%[E]%RESET%xecute  %TXT_MAG%[T]%RESET%oggle Filter  %TXT_RED%[B]%RESET%ack\r
choice /c WSETB /n >nul\r
set "NAV_CHOICE=!errorlevel!"\r
if "!NAV_CHOICE!"=="5" goto MAIN_MENU\r
if "!NAV_CHOICE!"=="4" ( if "!SHOW_ACTIVE_ONLY!"=="0" (set "SHOW_ACTIVE_ONLY=1") else (set "SHOW_ACTIVE_ONLY=0") & goto EXPLORER_REBUILD_LIST )\r
if "!NAV_CHOICE!"=="3" goto EXPLORER_ACTION_INIT\r
if "!NAV_CHOICE!"=="2" ( if !current_index! LSS !total_apps! set /a current_index+=1 & goto EXPLORER_RENDER )\r
if "!NAV_CHOICE!"=="1" ( if !current_index! GTR 1 set /a current_index-=1 & goto EXPLORER_RENDER )\r
goto EXPLORER_RENDER\r
\r
:EXPLORER_ACTION_INIT\r
set "sel_pkg=!app_pkg[%current_index%]!"\r
call :GET_APP_NAME !sel_pkg!\r
set "sel_lbl=!APP_LABEL!"\r
\r
:EXPLORER_ACTION_LOOP\r
call :CHECK_APP_STATE !sel_pkg!\r
cls\r
echo  %BOLD%App Name:%RESET%    %TXT_WHT%!sel_lbl!%RESET%\r
echo  %BOLD%Package ID:%RESET%  %TXT_WHT%!sel_pkg!%RESET%\r
echo  %BOLD%App Status:%RESET%  !APP_STATE_COLOR!!APP_STATE!%RESET%\r
echo.\r
echo  %TXT_GRN%[F]%RESET% Remove / Freeze   %TXT_CYAN%[R]%RESET% Unfreeze / Restore   %TXT_YEL%[B]%RESET%ack\r
choice /c FRB /n >nul\r
if "!errorlevel!"=="3" goto EXPLORER_REBUILD_LIST\r
if "!errorlevel!"=="1" (\r
    if "!DISABLE_MODE!"=="1" (\r
        if "!SIM_MODE!"=="1" ( echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm disable-user --user 0 !sel_pkg! ) else ( !ADB_CMD! -s !TARGET_ID! shell pm disable-user --user 0 !sel_pkg! >nul 2>&1 )\r
        echo %time% ^| FREEZE ^| !sel_pkg! >> "!LOGFILE!"\r
    ) else (\r
        if "!SIM_MODE!"=="1" ( echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm uninstall -k --user 0 !sel_pkg! ) else ( !ADB_CMD! -s !TARGET_ID! shell pm uninstall -k --user 0 !sel_pkg! >nul 2>&1 )\r
        echo %time% ^| UNINSTALL ^| !sel_pkg! >> "!LOGFILE!"\r
    )\r
)\r
if "!errorlevel!"=="2" (\r
    if "!SIM_MODE!"=="1" (\r
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell cmd package install-existing !sel_pkg!\r
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm enable !sel_pkg!\r
    ) else (\r
        !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing !sel_pkg! >nul 2>&1\r
        !ADB_CMD! -s !TARGET_ID! shell pm enable !sel_pkg! >nul 2>&1\r
    )\r
    echo %time% ^| RESTORE ^| !sel_pkg! >> "!LOGFILE!"\r
)\r
if "!SIM_MODE!"=="1" timeout /t 2 >nul\r
call :CACHE_DEVICE_STATE\r
timeout /t 1 >nul\r
goto EXPLORER_ACTION_LOOP\r
\r
:: ===============================================================================================\r
::  STANDARD DEBLOAT: STEP 2 & JOYOSE LOGIC\r
:: ===============================================================================================\r
:MODE_SELECT\r
:: Reinitialize working lists from base copies\r
set "apps_p1=%BASE_APPS_P1%"\r
set "apps_p4=%BASE_APPS_P4%"\r
set "apps_restore_only=%BASE_APPS_RESTORE_ONLY%"\r
cls\r
echo.\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%%TXT_WHT%  STEP 2: SELECT OPERATION MODE%RESET%\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo.\r
if "!DISABLE_MODE!"=="1" (\r
    echo  %TXT_GRN%[F]%RESET%reeze Bloatware %TXT_GRAY%(Current Setting: pm disable-user)%RESET%\r
) else (\r
    echo  %TXT_GRN%[S]%RESET%afe Remove Bloatware %TXT_GRAY%(Current Setting: uninstall -k)%RESET%\r
)\r
echo  %TXT_CYAN%[R]%RESET%estore System Apps %TXT_GRAY%(Recovery Mode)%RESET%\r
echo.\r
\r
if "!DISABLE_MODE!"=="1" ( choice /c FR /n >nul ) else ( choice /c SR /n >nul )\r
\r
if errorlevel 2 (\r
    set "CMD_ACTION=RESTORE"\r
    set "MODE_NAME=RESTORE"\r
    set "MODE_VERB=Restore"\r
    set "apps_p4=!apps_p4! !apps_restore_only!"\r
) else (\r
    if "!DISABLE_MODE!"=="1" (\r
        set "CMD_ACTION=pm disable-user --user 0"\r
        set "MODE_NAME=FREEZE"\r
        set "MODE_VERB=Freeze"\r
    ) else (\r
        set "CMD_ACTION=pm uninstall -k --user 0"\r
        set "MODE_NAME=SAFE_REMOVE"\r
        set "MODE_VERB=Safe Remove"\r
    )\r
    \r
    :: Handle Joyose via JSON setting\r
    if /I "!JOYOSE_ACTION!"=="ASK" (\r
        cls\r
        echo.\r
        echo  %BG_YEL%  JOYOSE THERMAL MANAGEMENT                                                                                          %RESET%\r
        echo  %TXT_WHT%com.xiaomi.joyose%RESET% manages thermal components. Needed on some devices to prevent overheating.\r
        echo.\r
        echo  Do you want to %MODE_VERB% Joyose?\r
        echo  %TXT_RED%[Y]%RESET%es - Remove it   %TXT_GRN%[N]%RESET%o - Keep it safe\r
        choice /c YN /n >nul\r
        if errorlevel 2 ( echo  -^> %TXT_GRN%Joyose kept.%RESET% ) else ( set "apps_p1=com.xiaomi.joyose !apps_p1!" )\r
        timeout /t 2 >nul\r
    ) else if /I "!JOYOSE_ACTION!"=="REMOVE" (\r
        set "apps_p1=com.xiaomi.joyose !apps_p1!"\r
    )\r
)\r
\r
if "!SHOW_PREVIEW!"=="1" (\r
    cls\r
    echo  %BG_GRN%  SAFE LIST (PHASE 1)                                                                                               %RESET%\r
    for %%a in (%apps_p1%) do echo   - %%a\r
    echo.\r
    echo  %TXT_GRAY%  Press any key to begin processing...%RESET%\r
    pause >nul\r
)\r
\r
:: ===============================================================================================\r
::  PHASES\r
:: ===============================================================================================\r
:PHASE1_INIT\r
cls\r
echo  %BG_GRN%  PHASE 1/4 ^| Ads, Analytics ^& Junk Services                                                                        %RESET%\r
echo  %TXT_GRN%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_GRN%[M]%RESET%anual Review %TXT_GRAY%(Recommended)%RESET%   %TXT_GRN%[S]%RESET%kip Phase\r
choice /c AMS /n >nul\r
set "P_CHOICE=%errorlevel%"\r
if "%P_CHOICE%"=="3" goto PHASE2_INIT\r
for %%p in (%apps_p1%) do (\r
    call :GET_APP_NAME %%p\r
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "SAFE" ) else ( call :ASK_USER %%p "!APP_LABEL!" "SAFE" )\r
)\r
\r
:PHASE2_INIT\r
cls\r
echo  %BG_YEL%  PHASE 2/4 ^| User Tools ^& Features                                                                                 %RESET%\r
echo  %TXT_YEL%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_YEL%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_YEL%[S]%RESET%kip Phase\r
choice /c AMS /n >nul\r
set "P_CHOICE=%errorlevel%"\r
if "%P_CHOICE%"=="3" goto PHASE3_INIT\r
for %%p in (%apps_p2%) do (\r
    call :GET_APP_NAME %%p\r
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "CAUTION" ) else ( call :ASK_USER %%p "!APP_LABEL!" "CAUTION" )\r
)\r
\r
:PHASE3_INIT\r
if "!PROTECT_CORE!"=="1" if "!MODE_NAME!" NEQ "RESTORE" (\r
    cls\r
    echo  %BG_RED%  PHASE 3/4 ^| Risky System Apps                                                                                      %RESET%\r
    echo.\r
    echo  %TXT_YEL%[!] Protect Core System Apps is ENABLED in config.%RESET%\r
    echo  %TXT_GRAY%Skipping Phase 3 to prevent potential bootloops.%RESET%\r
    timeout /t 3 >nul\r
    goto PHASE4_INIT\r
)\r
\r
cls\r
echo  %BG_RED%  PHASE 3/4 ^| Risky System Apps                                                                                      %RESET%\r
echo  %TXT_RED%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_RED%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_RED%[S]%RESET%kip Phase\r
choice /c AMS /n >nul\r
set "P_CHOICE=%errorlevel%"\r
if "%P_CHOICE%"=="3" goto PHASE4_INIT\r
for %%p in (%apps_p3%) do (\r
    call :GET_APP_NAME %%p\r
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "DANGER" ) else ( call :ASK_USER %%p "!APP_LABEL!" "DANGER" )\r
)\r
\r
:PHASE4_INIT\r
cls\r
echo  %BG_MAG%  PHASE 4/4 ^| Hidden System Apps                                                                                     %RESET%\r
echo  %TXT_MAG%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_MAG%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_MAG%[S]%RESET%kip Phase\r
choice /c AMS /n >nul\r
set "P_CHOICE=%errorlevel%"\r
if "%P_CHOICE%"=="3" goto FINISH\r
for %%p in (%apps_p4%) do (\r
    call :GET_APP_NAME %%p\r
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "HIDDEN" ) else ( call :ASK_USER %%p "!APP_LABEL!" "HIDDEN" )\r
)\r
\r
:FINISH\r
cls\r
echo.\r
echo  %BG_CYAN%  TASK COMPLETED                                                                                                     %RESET%\r
echo.\r
echo  Press any key to return to Main Menu...\r
call :CACHE_DEVICE_STATE\r
pause >nul\r
goto MAIN_MENU\r
\r
:: ===============================================================================================\r
::  SUBROUTINES\r
:: ===============================================================================================\r
:CACHE_DEVICE_STATE\r
!ADB_CMD! -s !TARGET_ID! shell pm list packages -u > "%temp%\adb_all.txt" 2>nul\r
!ADB_CMD! -s !TARGET_ID! shell pm list packages -e > "%temp%\adb_active.txt" 2>nul\r
!ADB_CMD! -s !TARGET_ID! shell pm list packages -d > "%temp%\adb_disabled.txt" 2>nul\r
goto :eof\r
\r
:CHECK_APP_STATE\r
set "CHK_PKG=%~1"\r
set "APP_STATE=Not Installed / Removed"\r
set "APP_STATE_COLOR=%TXT_GRAY%"\r
findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_all.txt" >nul 2>&1\r
if !errorlevel! equ 0 (\r
    set "APP_STATE=Uninstalled (User 0)"\r
    set "APP_STATE_COLOR=%TXT_YEL%"\r
    findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_active.txt" >nul 2>&1\r
    if !errorlevel! equ 0 ( set "APP_STATE=Installed (Active)" & set "APP_STATE_COLOR=%TXT_GRN%" )\r
    findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_disabled.txt" >nul 2>&1\r
    if !errorlevel! equ 0 ( set "APP_STATE=Frozen (Disabled)" & set "APP_STATE_COLOR=%TXT_CYAN%" )\r
)\r
goto :eof\r
\r
:EXECUTE_ACTION\r
set "pkg=%~1"\r
set "lbl=%~2"\r
call :CHECK_APP_STATE %pkg%\r
if "!SKIP_NOT_INSTALLED!"=="1" (\r
    if "!MODE_NAME!"=="RESTORE" ( if "!APP_STATE!"=="Installed (Active)" goto :eof )\r
    if "!MODE_NAME!"=="SAFE_REMOVE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )\r
    if "!MODE_NAME!"=="FREEZE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )\r
)\r
\r
echo  Processing: %TXT_WHT%!lbl!%RESET% ^(!pkg!^)\r
if "!MODE_NAME!"=="RESTORE" (\r
    if "!SIM_MODE!"=="1" (\r
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell cmd package install-existing %pkg%\r
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm enable %pkg%\r
    ) else (\r
        !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing %pkg% >nul 2>&1\r
        !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1\r
    )\r
) else ( \r
    if "!SIM_MODE!"=="1" (\r
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell %CMD_ACTION% %pkg%\r
    ) else (\r
        !ADB_CMD! -s !TARGET_ID! shell %CMD_ACTION% %pkg% >nul 2>&1\r
    )\r
)\r
echo %time% ^| EXECUTE ^| %pkg% >> "!LOGFILE!"\r
if "!SIM_MODE!"=="1" timeout /t 1 >nul\r
goto :eof\r
\r
:ASK_USER\r
set "pkg=%~1"\r
set "lbl=%~2"\r
call :CHECK_APP_STATE %pkg%\r
if "!SKIP_NOT_INSTALLED!"=="1" (\r
    if "!MODE_NAME!"=="RESTORE" ( if "!APP_STATE!"=="Installed (Active)" goto :eof )\r
    if "!MODE_NAME!"=="SAFE_REMOVE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )\r
    if "!MODE_NAME!"=="FREEZE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )\r
)\r
\r
set "CHOICES=YNE"\r
set "P_TXT=>> %MODE_VERB%?  %TXT_GRN%[Y]%RESET%es   %TXT_RED%[N]%RESET%o   %TXT_CYAN%[E]%RESET% Exit"\r
if "!APP_STATE!"=="Frozen (Disabled)" ( set "CHOICES=YNEU" & set "P_TXT=>> %MODE_VERB%?  %TXT_GRN%[Y]%RESET%es   %TXT_RED%[N]%RESET%o   %TXT_YEL%[U]%RESET%nfreeze   %TXT_CYAN%[E]%RESET% Exit" )\r
\r
cls\r
echo  %TXT_GRAY%====================================================================================================================%RESET%\r
echo  %BOLD%!lbl!%RESET% ^(%pkg%^)\r
echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%\r
echo.\r
echo  !P_TXT!\r
\r
choice /c !CHOICES! /n >nul\r
if errorlevel 4 (\r
    if "!SIM_MODE!"=="1" ( echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm enable %pkg% & timeout /t 2 >nul ) else ( !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1 )\r
    goto :eof\r
)\r
if errorlevel 3 goto FINISH\r
if errorlevel 2 goto :eof\r
call :EXECUTE_ACTION %pkg% "!lbl!" "MANUAL"\r
goto :eof\r
\r
:GET_APP_NAME\r
set "pkg=%~1"\r
set "APP_LABEL=!DESC_%pkg%!"\r
if "!APP_LABEL!"=="" set "APP_LABEL=%pkg%"\r
goto :eof\r
