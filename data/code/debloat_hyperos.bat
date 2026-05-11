@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=50
title Xiaomi HyperOS Debloat Commander v17.9

:: Secure absolute paths
for %%A in ("%~dp0..\..") do set "ROOT_DIR=%%~fA"
set "CONFIG_PATH=%ROOT_DIR%\data\config\config.json"
set "SERVICES_PATH=%ROOT_DIR%\data\config\services.json"
set "LOGS_DIR=%ROOT_DIR%\logs"

:: Validate JSON Integrity
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: One of your JSON files contains syntax errors or is missing.
    pause & exit
)

:: Securely dump JSON variables directly into Batch
set "TEMP_VARS=%temp%\hyperos_vars_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $s = Get-Content -Raw '%SERVICES_PATH%' | ConvertFrom-Json; 'set JOYOSE_ACTION=' + $c.settings.joyoseAction; 'set SKIP_NOT_INSTALLED=' + [int][bool]$c.settings.smartFiltering; 'set SHOW_PREVIEW=' + [int][bool]$c.settings.showPreview; 'set LOG_ENABLED=' + [int][bool]$c.settings.logToText; 'set SIM_MODE=' + [int][bool]$c.settings.simulationMode; 'set DISABLE_MODE=' + [int][bool]$c.settings.disableInsteadOfUninstall; 'set PROTECT_CORE=' + [int][bool]$c.settings.skipSystemCore; 'set FORCE_ADB=' + [int][bool]$c.settings.forceADBRestart; 'set ADB_PATH=' + $c.settings.defaultAdbPath; 'set apps_p1=' + ($s.phases.phase1_safe -join ' '); 'set apps_p2=' + ($s.phases.phase2_advanced -join ' '); 'set apps_p3=' + ($s.phases.phase3_risky -join ' '); 'set apps_p4=' + ($s.phases.phase4_hidden -join ' '); 'set apps_restore_only=' + ($s.phases.restore_only -join ' '); $s.descriptions.PSObject.Properties | ForEach-Object { 'set DESC_' + $_.Name + '=' + $_.Value }" > "%TEMP_VARS%"
call "%TEMP_VARS%"
del "%TEMP_VARS%"

:: Create immutable base copies of phase lists
set "BASE_APPS_P1=%apps_p1%"
set "BASE_APPS_P4=%apps_p4%"
set "BASE_APPS_RESTORE_ONLY=%apps_restore_only%"

:: ADB Setup
set "ADB_CMD=!ADB_PATH!"
if exist "%ROOT_DIR%\!ADB_PATH!" set "ADB_CMD=%ROOT_DIR%\!ADB_PATH!"

:: ANSI Colors Setup
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "BG_CYAN=%ESC%[46m%ESC%[30m"
set "BG_MAG=%ESC%[45m%ESC%[30m"
set "BG_GRN=%ESC%[42m%ESC%[30m"
set "BG_YEL=%ESC%[43m%ESC%[30m"
set "BG_RED=%ESC%[41m%ESC%[97m"
set "TXT_CYAN=%ESC%[96m"
set "TXT_GRN=%ESC%[92m"
set "TXT_YEL=%ESC%[93m"
set "TXT_RED=%ESC%[91m"
set "TXT_MAG=%ESC%[95m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

:: Log File Setup
set "LOGFILE=NUL"
if "!LOG_ENABLED!"=="1" (
    if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"
    set "SAFE_DT=%DATE:/=-%"
    set "SAFE_DT=!SAFE_DT:\=-!"
    set "SAFE_DT=!SAFE_DT:.=-!"
    set "SAFE_TM=%TIME::=-%"
    set "SAFE_TM=!SAFE_TM:.=-!"
    set "SAFE_TM=!SAFE_TM: =0!"
    set "LOGFILE=%LOGS_DIR%\Debloat_Log_!SAFE_DT!_!SAFE_TM!.log"
    echo [LOG STARTED] > "!LOGFILE!"
    echo Target OS: Xiaomi HyperOS >> "!LOGFILE!"
    echo Date: %date% %time% >> "!LOGFILE!"
    echo -------------------------------------------------------- >> "!LOGFILE!"
)

:: ADB Server Initialization
if "!FORCE_ADB!"=="1" (
    !ADB_CMD! kill-server >nul 2>&1
)
!ADB_CMD! start-server >nul 2>&1

:: ===============================================================================================
::  AUTO-SCANNING DEVICE CONNECTION
:: ===============================================================================================
:CHECK_DEVICES
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT COMMANDER %TXT_CYAN%-%TXT_WHT% System Ready%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
if "!SIM_MODE!"=="1" echo  %BG_YEL%  [DEBUG SIMULATION MODE ACTIVE] Commands will NOT be executed on the device!                        %RESET%
echo.
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                      %RESET%
echo  %TXT_GRAY%Auto-scanning for connected devices...
echo  %TXT_GRAY%Ensure USB Debugging is ON.%RESET%
echo.
echo  Press %TXT_RED%[E]%RESET% to cancel and return to Manager.

set count=0
for /f "skip=1 tokens=1,2,*" %%a in ('!ADB_CMD! devices -l') do (
    if "%%b" == "device" (
        set /a count+=1
        set "device[!count!]=%%a"
        for /f "tokens=*" %%m in ('!ADB_CMD! -s %%a shell getprop ro.product.model') do set "model[!count!]=%%m"
    )
)

if !count! GTR 0 (
    set "TARGET_ID=!device[1]!"
    set "TARGET_MODEL=!model[1]!"
    echo.
    echo  %TXT_GRN%  [v]%RESET% Connected Model: %TXT_WHT%!TARGET_MODEL!%RESET%
    timeout /t 2 >nul
    call :CACHE_DEVICE_STATE
    goto MAIN_MENU
)

:: Wait 2 seconds, default to R (Retry), exit if user presses E
choice /c RE /n /t 2 /d R >nul
if errorlevel 2 goto :eof
goto CHECK_DEVICES

:: ===============================================================================================
::  MAIN MENU
:: ===============================================================================================
:MAIN_MENU
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  MAIN MENU %TXT_CYAN%-%TXT_WHT% Select Functionality%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRN%[1] Standard Debloat (Phases 1-4)%RESET%
echo  %TXT_CYAN%[2] Interactive App Explorer%RESET%
echo  %TXT_YEL%[3] Refresh Device Cache%RESET%
echo  %TXT_RED%[E] Return to Manager%RESET%
echo.
echo  Press %TXT_GRN%[1]%RESET%, %TXT_CYAN%[2]%RESET%, %TXT_YEL%[3]%RESET%, or %TXT_RED%[E]%RESET% Exit...

choice /c 123E /n >nul
if errorlevel 4 goto :eof
if errorlevel 3 ( call :CACHE_DEVICE_STATE & goto MAIN_MENU )
if errorlevel 2 goto INTERACTIVE_EXPLORER_INIT
if errorlevel 1 goto MODE_SELECT

:: ===============================================================================================
::  INTERACTIVE EXPLORER
:: ===============================================================================================
:INTERACTIVE_EXPLORER_INIT
set "SHOW_ACTIVE_ONLY=0"
set "all_db_apps=%apps_p1% %apps_p2% %apps_p3% %apps_p4% com.xiaomi.joyose"

:EXPLORER_REBUILD_LIST
cls
if exist "%temp%\matched_apps.txt" del "%temp%\matched_apps.txt"

for %%p in (!all_db_apps!) do (
    if "!SHOW_ACTIVE_ONLY!"=="1" (
        findstr /I /C:"package:%%p" "%temp%\adb_active.txt" >nul 2>&1
    ) else (
        findstr /I /C:"package:%%p" "%temp%\adb_all.txt" >nul 2>&1
    )
    if !errorlevel! equ 0 (
        call :GET_APP_NAME %%p
        echo !APP_LABEL!^|%%p>> "%temp%\matched_apps.txt"
    )
)

set "total_apps=0"
if exist "%temp%\matched_apps.txt" (
    for /f "tokens=1,2 delims=|" %%A in ('sort "%temp%\matched_apps.txt"') do (
        set /a total_apps+=1
        set "app_list[!total_apps!]=%%A ^(%%B^)"
        set "app_pkg[!total_apps!]=%%B"
    )
    del "%temp%\matched_apps.txt" >nul 2>&1
)

if !total_apps!==0 (
    echo  %TXT_RED%[!] No apps found for the current filter.%RESET%
    pause
    goto MAIN_MENU
)
set "current_index=1"
set "window_size=25"

:EXPLORER_RENDER
cls
echo  %BG_CYAN%  INTERACTIVE APP EXPLORER ^| App !current_index! of !total_apps!                                                                  %RESET%
echo.
set /a half_window=window_size / 2
set /a start_idx=current_index - half_window
if !start_idx! LSS 1 set start_idx=1
set /a end_idx=start_idx + window_size - 1
if !end_idx! GTR !total_apps! (
    set end_idx=!total_apps!
    set /a start_idx=end_idx - window_size + 1
    if !start_idx! LSS 1 set start_idx=1
)

for /L %%i in (!start_idx!,1,!end_idx!) do (
    if %%i==!current_index! ( echo   %BG_CYAN%%TXT_WHT% ^> !app_list[%%i]! %RESET% ) else ( echo      !app_list[%%i]! )
)
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Controls: %TXT_GRN%[W]%RESET% Up  %TXT_GRN%[S]%RESET% Down  %TXT_YEL%[E]%RESET%xecute  %TXT_MAG%[T]%RESET%oggle Filter  %TXT_RED%[B]%RESET%ack
choice /c WSETB /n >nul
set "NAV_CHOICE=!errorlevel!"
if "!NAV_CHOICE!"=="5" goto MAIN_MENU
if "!NAV_CHOICE!"=="4" ( if "!SHOW_ACTIVE_ONLY!"=="0" (set "SHOW_ACTIVE_ONLY=1") else (set "SHOW_ACTIVE_ONLY=0") & goto EXPLORER_REBUILD_LIST )
if "!NAV_CHOICE!"=="3" goto EXPLORER_ACTION_INIT
if "!NAV_CHOICE!"=="2" ( if !current_index! LSS !total_apps! set /a current_index+=1 & goto EXPLORER_RENDER )
if "!NAV_CHOICE!"=="1" ( if !current_index! GTR 1 set /a current_index-=1 & goto EXPLORER_RENDER )
goto EXPLORER_RENDER

:EXPLORER_ACTION_INIT
set "sel_pkg=!app_pkg[%current_index%]!"
call :GET_APP_NAME !sel_pkg!
set "sel_lbl=!APP_LABEL!"

:EXPLORER_ACTION_LOOP
call :CHECK_APP_STATE !sel_pkg!
cls
echo  %BOLD%App Name:%RESET%    %TXT_WHT%!sel_lbl!%RESET%
echo  %BOLD%Package ID:%RESET%  %TXT_WHT%!sel_pkg!%RESET%
echo  %BOLD%App Status:%RESET%  !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  %TXT_GRN%[F]%RESET% Remove / Freeze   %TXT_CYAN%[R]%RESET% Unfreeze / Restore   %TXT_YEL%[B]%RESET%ack
choice /c FRB /n >nul
if "!errorlevel!"=="3" goto EXPLORER_REBUILD_LIST
if "!errorlevel!"=="1" (
    if "!DISABLE_MODE!"=="1" (
        if "!SIM_MODE!"=="1" ( echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm disable-user --user 0 !sel_pkg! ) else ( !ADB_CMD! -s !TARGET_ID! shell pm disable-user --user 0 !sel_pkg! >nul 2>&1 )
        echo %time% ^| FREEZE ^| !sel_pkg! >> "!LOGFILE!"
    ) else (
        if "!SIM_MODE!"=="1" ( echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm uninstall -k --user 0 !sel_pkg! ) else ( !ADB_CMD! -s !TARGET_ID! shell pm uninstall -k --user 0 !sel_pkg! >nul 2>&1 )
        echo %time% ^| UNINSTALL ^| !sel_pkg! >> "!LOGFILE!"
    )
)
if "!errorlevel!"=="2" (
    if "!SIM_MODE!"=="1" (
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell cmd package install-existing !sel_pkg!
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm enable !sel_pkg!
    ) else (
        !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing !sel_pkg! >nul 2>&1
        !ADB_CMD! -s !TARGET_ID! shell pm enable !sel_pkg! >nul 2>&1
    )
    echo %time% ^| RESTORE ^| !sel_pkg! >> "!LOGFILE!"
)
if "!SIM_MODE!"=="1" timeout /t 2 >nul
call :CACHE_DEVICE_STATE
timeout /t 1 >nul
goto EXPLORER_ACTION_LOOP

:: ===============================================================================================
::  STANDARD DEBLOAT: STEP 2 & JOYOSE LOGIC
:: ===============================================================================================
:MODE_SELECT
:: Reinitialize working lists from immutable base copies
set "apps_p1=%BASE_APPS_P1%"
set "apps_p4=%BASE_APPS_P4%"
set "apps_restore_only=%BASE_APPS_RESTORE_ONLY%"
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  STEP 2: SELECT OPERATION MODE%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
if "!DISABLE_MODE!"=="1" (
    echo  %TXT_GRN%[F]%RESET%reeze Bloatware %TXT_GRAY%(Current Setting: pm disable-user)%RESET%
) else (
    echo  %TXT_GRN%[S]%RESET%afe Remove Bloatware %TXT_GRAY%(Current Setting: uninstall -k)%RESET%
)
echo  %TXT_CYAN%[R]%RESET%estore System Apps %TXT_GRAY%(Recovery Mode)%RESET%
echo.

if "!DISABLE_MODE!"=="1" ( choice /c FR /n >nul ) else ( choice /c SR /n >nul )

if errorlevel 2 (
    set "CMD_ACTION=RESTORE"
    set "MODE_NAME=RESTORE"
    set "MODE_VERB=Restore"
    set "apps_p4=!apps_p4! !apps_restore_only!"
) else (
    if "!DISABLE_MODE!"=="1" (
        set "CMD_ACTION=pm disable-user --user 0"
        set "MODE_NAME=FREEZE"
        set "MODE_VERB=Freeze"
    ) else (
        set "CMD_ACTION=pm uninstall -k --user 0"
        set "MODE_NAME=SAFE_REMOVE"
        set "MODE_VERB=Safe Remove"
    )
    
    :: Handle Joyose via JSON setting
    if /I "!JOYOSE_ACTION!"=="ASK" (
        cls
        echo.
        echo  %BG_YEL%  JOYOSE THERMAL MANAGEMENT                                                                                          %RESET%
        echo  %TXT_WHT%com.xiaomi.joyose%RESET% manages thermal components. Needed on some devices to prevent overheating.
        echo.
        echo  Do you want to %MODE_VERB% Joyose?
        echo  %TXT_RED%[Y]%RESET%es - Remove it   %TXT_GRN%[N]%RESET%o - Keep it safe
        choice /c YN /n >nul
        if errorlevel 2 ( echo  -^> %TXT_GRN%Joyose kept.%RESET% ) else ( set "apps_p1=com.xiaomi.joyose !apps_p1!" )
        timeout /t 2 >nul
    ) else if /I "!JOYOSE_ACTION!"=="REMOVE" (
        set "apps_p1=com.xiaomi.joyose !apps_p1!"
    )
)

if "!SHOW_PREVIEW!"=="1" (
    cls
    echo  %BG_GRN%  SAFE LIST (PHASE 1)                                                                                               %RESET%
    for %%a in (%apps_p1%) do echo   - %%a
    echo.
    echo  %TXT_GRAY%  Press any key to begin processing...%RESET%
    pause >nul
)

:: ===============================================================================================
::  PHASES
:: ===============================================================================================
:PHASE1_INIT
cls
echo  %BG_GRN%  PHASE 1/4 ^| Ads, Analytics ^& Junk Services                                                                        %RESET%
echo  %TXT_GRN%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_GRN%[M]%RESET%anual Review %TXT_GRAY%(Recommended)%RESET%   %TXT_GRN%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto PHASE2_INIT
for %%p in (%apps_p1%) do (
    call :GET_APP_NAME %%p
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "SAFE" ) else ( call :ASK_USER %%p "!APP_LABEL!" "SAFE" )
)

:PHASE2_INIT
cls
echo  %BG_YEL%  PHASE 2/4 ^| User Tools ^& Features                                                                                 %RESET%
echo  %TXT_YEL%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_YEL%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_YEL%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto PHASE3_INIT
for %%p in (%apps_p2%) do (
    call :GET_APP_NAME %%p
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "CAUTION" ) else ( call :ASK_USER %%p "!APP_LABEL!" "CAUTION" )
)

:PHASE3_INIT
if "!PROTECT_CORE!"=="1" if "!MODE_NAME!" NEQ "RESTORE" (
    cls
    echo  %BG_RED%  PHASE 3/4 ^| Risky System Apps                                                                                      %RESET%
    echo.
    echo  %TXT_YEL%[!] Protect Core System Apps is ENABLED in config.%RESET%
    echo  %TXT_GRAY%Skipping Phase 3 to prevent potential bootloops.%RESET%
    timeout /t 3 >nul
    goto PHASE4_INIT
)

cls
echo  %BG_RED%  PHASE 3/4 ^| Risky System Apps                                                                                      %RESET%
echo  %TXT_RED%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_RED%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_RED%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto PHASE4_INIT
for %%p in (%apps_p3%) do (
    call :GET_APP_NAME %%p
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "DANGER" ) else ( call :ASK_USER %%p "!APP_LABEL!" "DANGER" )
)

:PHASE4_INIT
cls
echo  %BG_MAG%  PHASE 4/4 ^| Hidden System Apps                                                                                     %RESET%
echo  %TXT_MAG%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_MAG%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_MAG%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto FINISH
for %%p in (%apps_p4%) do (
    call :GET_APP_NAME %%p
    if "!P_CHOICE!"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "HIDDEN" ) else ( call :ASK_USER %%p "!APP_LABEL!" "HIDDEN" )
)

:FINISH
cls
echo.
echo  %BG_CYAN%  TASK COMPLETED                                                                                                     %RESET%
echo.
echo  Press any key to return to Main Menu...
call :CACHE_DEVICE_STATE
pause >nul
goto MAIN_MENU

:: ===============================================================================================
::  SUBROUTINES
:: ===============================================================================================
:CACHE_DEVICE_STATE
!ADB_CMD! -s !TARGET_ID! shell pm list packages -u > "%temp%\adb_all.txt" 2>nul
!ADB_CMD! -s !TARGET_ID! shell pm list packages -e > "%temp%\adb_active.txt" 2>nul
!ADB_CMD! -s !TARGET_ID! shell pm list packages -d > "%temp%\adb_disabled.txt" 2>nul
goto :eof

:CHECK_APP_STATE
set "CHK_PKG=%~1"
set "APP_STATE=Not Installed / Removed"
set "APP_STATE_COLOR=%TXT_GRAY%"
findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_all.txt" >nul 2>&1
if !errorlevel! equ 0 (
    set "APP_STATE=Uninstalled (User 0)"
    set "APP_STATE_COLOR=%TXT_YEL%"
    findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_active.txt" >nul 2>&1
    if !errorlevel! equ 0 ( set "APP_STATE=Installed (Active)" & set "APP_STATE_COLOR=%TXT_GRN%" )
    findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_disabled.txt" >nul 2>&1
    if !errorlevel! equ 0 ( set "APP_STATE=Frozen (Disabled)" & set "APP_STATE_COLOR=%TXT_CYAN%" )
)
goto :eof

:EXECUTE_ACTION
set "pkg=%~1"
set "lbl=%~2"
call :CHECK_APP_STATE %pkg%
if "!SKIP_NOT_INSTALLED!"=="1" (
    if "!MODE_NAME!"=="RESTORE" ( if "!APP_STATE!"=="Installed (Active)" goto :eof )
    if "!MODE_NAME!"=="SAFE_REMOVE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )
    if "!MODE_NAME!"=="FREEZE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )
)

echo  Processing: %TXT_WHT%!lbl!%RESET% ^(!pkg!^)
if "!MODE_NAME!"=="RESTORE" (
    if "!SIM_MODE!"=="1" (
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell cmd package install-existing %pkg%
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm enable %pkg%
    ) else (
        !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing %pkg% >nul 2>&1
        !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1
    )
) else ( 
    if "!SIM_MODE!"=="1" (
        echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell %CMD_ACTION% %pkg%
    ) else (
        !ADB_CMD! -s !TARGET_ID! shell %CMD_ACTION% %pkg% >nul 2>&1
    )
)
echo %time% ^| EXECUTE ^| %pkg% >> "!LOGFILE!"
if "!SIM_MODE!"=="1" timeout /t 1 >nul
goto :eof

:ASK_USER
set "pkg=%~1"
set "lbl=%~2"
call :CHECK_APP_STATE %pkg%
if "!SKIP_NOT_INSTALLED!"=="1" (
    if "!MODE_NAME!"=="RESTORE" ( if "!APP_STATE!"=="Installed (Active)" goto :eof )
    if "!MODE_NAME!"=="SAFE_REMOVE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )
    if "!MODE_NAME!"=="FREEZE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )
)

set "CHOICES=YNE"
set "P_TXT=>> %MODE_VERB%?  %TXT_GRN%[Y]%RESET%es   %TXT_RED%[N]%RESET%o   %TXT_CYAN%[E]%RESET% Exit"
if "!APP_STATE!"=="Frozen (Disabled)" ( set "CHOICES=YNEU" & set "P_TXT=>> %MODE_VERB%?  %TXT_GRN%[Y]%RESET%es   %TXT_RED%[N]%RESET%o   %TXT_YEL%[U]%RESET%nfreeze   %TXT_CYAN%[E]%RESET% Exit" )

cls
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%!lbl!%RESET% ^(%pkg%^)
echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  !P_TXT!

choice /c !CHOICES! /n >nul
if errorlevel 4 (
    if "!SIM_MODE!"=="1" ( echo  %TXT_MAG%[DEBUG]%RESET% !ADB_CMD! shell pm enable %pkg% & timeout /t 2 >nul ) else ( !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1 )
    goto :eof
)
if errorlevel 3 goto FINISH
if errorlevel 2 goto :eof
call :EXECUTE_ACTION %pkg% "!lbl!" "MANUAL"
goto :eof

:GET_APP_NAME
set "pkg=%~1"
set "APP_LABEL=!DESC_%pkg%!"
if "!APP_LABEL!"=="" set "APP_LABEL=%pkg%"
goto :eof