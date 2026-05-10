@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=50
title Xiaomi HyperOS Debloat Commander v17.1 (Optimized)
cd /d "%~dp0"

:: Ensure ADB command is absolute if present in folder, else rely on PATH
set "ADB_CMD=adb"
if exist "%~dp0adb.exe" set "ADB_CMD="%~dp0adb.exe""

:: Load shared configuration instead of hardcoded lists
call "%~dp0config.cmd"

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
set "SAFE_DT=%DATE:/=-%"
set "SAFE_DT=%SAFE_DT:\=-%"
set "SAFE_DT=%SAFE_DT:.=-%"
set "SAFE_TM=%TIME::=-%"
set "SAFE_TM=%SAFE_TM:.=-%"
set "SAFE_TM=%SAFE_TM: =0%"
set "LOGFILE=Debloat_Log_%SAFE_DT%_%SAFE_TM%.txt"

echo [LOG STARTED] > "%LOGFILE%"
echo Target OS: Xiaomi HyperOS >> "%LOGFILE%"
echo Date: %date% %time% >> "%LOGFILE%"
echo -------------------------------------------------------- >> "%LOGFILE%"

:: ===============================================================================================
::  STARTUP DASHBOARD
:: ===============================================================================================
color 0B
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT COMMANDER %TXT_CYAN%-%TXT_WHT% v17.1 Optimized %TXT_CYAN%-%TXT_WHT% System Ready%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%  [+]%TXT_WHT% Target OS:       Xiaomi HyperOS / MIUI (Android 13/14+)%RESET%
echo  %TXT_CYAN%  [+]%TXT_WHT% Database:        130+ Bloatware Packages Loaded (4 Phases)%RESET%
echo.
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                      %RESET%
!ADB_CMD! start-server >nul 2>&1

:CHECK_DEVICES
echo.
echo  %TXT_GRAY%  Scanning USB ports...%RESET%

set count=0
for /f "skip=1 tokens=1,*" %%a in ('!ADB_CMD! devices -l') do (
    if not "%%a" == "" (
        set /a count+=1
        set "device[!count!]=%%a"
        for /f "tokens=*" %%m in ('!ADB_CMD! -s %%a shell getprop ro.product.model') do set "model[!count!]=%%m"
    )
)

if %count%==0 (
    echo.
    echo  %BG_RED%  ERROR: CONNECTION FAILED                                                                                          %RESET%
    echo  %TXT_RED%  [!]%RESET% No device detected via ADB. Check USB Debugging and Cable.
    echo.
    echo  %TXT_GRAY%  Press any key to retry...%RESET%
    pause >nul
    cls
    goto CHECK_DEVICES
)

if %count%==1 (
    set "TARGET_ID=!device[1]!"
    set "TARGET_MODEL=!model[1]!"
    echo.
    echo  %BG_GRN%  DEVICE CONNECTED                                                                                                  %RESET%
    echo  %TXT_GRN%  [v]%RESET% Model: %TXT_WHT%!TARGET_MODEL!%RESET%
    echo  %TXT_GRN%  [v]%RESET% ID:    %TXT_WHT%!TARGET_ID!%RESET%

    echo Device Model: !TARGET_MODEL! >> "%LOGFILE%"
    echo Device ID: !TARGET_ID! >> "%LOGFILE%"
    echo -------------------------------------------------------- >> "%LOGFILE%"

    timeout /t 1 >nul
    call :CACHE_DEVICE_STATE
    goto MAIN_MENU
)

:: Multiple Devices
echo.
echo  %BG_YEL%  MULTIPLE DEVICES FOUND                                                                                            %RESET%
for /L %%i in (1,1,%count%) do (
    echo   %TXT_WHT%[%%i]%RESET% !model[%%i]! ^(!device[%%i]!^)
)
echo.
set /p "selection=  >> Select Device (1-%count%): "
set "TARGET_ID=!device[%selection%]!"
set "TARGET_MODEL=!model[%selection%]!"

echo Device Model: !TARGET_MODEL! >> "%LOGFILE%"
echo Device ID: !TARGET_ID! >> "%LOGFILE%"
echo -------------------------------------------------------- >> "%LOGFILE%"

echo.
echo  %TXT_GRN%  [+]%RESET% Selected: !TARGET_MODEL!
timeout /t 1 >nul
call :CACHE_DEVICE_STATE

:MAIN_MENU
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  MAIN MENU %TXT_CYAN%-%TXT_WHT% Select Functionality%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRN%[1] Standard Debloat (Phases 1-4)%RESET%
echo      Automated or guided debloating using the built-in database of 130+ known packages.
echo.
echo  %TXT_CYAN%[2] Interactive App Explorer (Filtered ^& Sorted)%RESET%
echo      Browse ONLY the bloatware apps currently installed/frozen on your device.
echo.
echo  %TXT_YEL%[3] Refresh Device Cache%RESET%
echo      Re-pulls the app states from the device if you've made manual changes.
echo.
echo  %TXT_RED%[E] Return to Manager%RESET%
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Press %TXT_GRN%[1]%RESET%, %TXT_CYAN%[2]%RESET%, %TXT_YEL%[3]%RESET%, or %TXT_RED%[E]%RESET%xit...

choice /c 123E /n >nul
if errorlevel 4 goto :eof
if errorlevel 3 (
    call :CACHE_DEVICE_STATE
    goto MAIN_MENU
)
if errorlevel 2 goto INTERACTIVE_EXPLORER_INIT
if errorlevel 1 goto MODE_SELECT

:: ===============================================================================================
::  INTERACTIVE EXPLORER
:: ===============================================================================================
:INTERACTIVE_EXPLORER_INIT
set "SHOW_ACTIVE_ONLY=0"
set "all_db_apps=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only% com.xiaomi.joyose"

:EXPLORER_REBUILD_LIST
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_CYAN%  INTERACTIVE APP EXPLORER                                                                                           %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRAY%Filtering local cache against database... Please wait...%RESET%

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
    echo.
    echo  %TXT_RED%[!] No apps found for the current filter.%RESET%
    pause
    if "!SHOW_ACTIVE_ONLY!"=="1" (
        set "SHOW_ACTIVE_ONLY=0"
        goto EXPLORER_REBUILD_LIST
    ) else (
        goto MAIN_MENU
    )
)
set "current_index=1"
set "window_size=25"

:EXPLORER_RENDER
cls
echo  %TXT_GRAY%====================================================================================================================%RESET%
if "!SHOW_ACTIVE_ONLY!"=="1" (
    echo  %BG_CYAN%  INTERACTIVE APP EXPLORER ^| App !current_index! of !total_apps! ^| Filter: ACTIVE APPS ONLY                                   %RESET%
) else (
    echo  %BG_CYAN%  INTERACTIVE APP EXPLORER ^| App !current_index! of !total_apps! ^| Filter: ALL DB APPS                                        %RESET%
)
echo  %TXT_GRAY%====================================================================================================================%RESET%
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
    if %%i==!current_index! (
        echo   %BG_CYAN%%TXT_WHT% ^> !app_list[%%i]! %RESET%
    ) else (
        echo      !app_list[%%i]!
    )
)

echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  %BOLD%Controls:%RESET% %TXT_GRN%[W]%RESET% Up   %TXT_GRN%[S]%RESET% Down   %TXT_CYAN%[A]%RESET% PgUp   %TXT_CYAN%[D]%RESET% PgDn   %TXT_YEL%[E]%RESET%xecute   %TXT_MAG%[T]%RESET%oggle Filter   %TXT_RED%[B]%RESET%ack
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%

choice /c WSADEBT /n >nul
set "NAV_CHOICE=!errorlevel!"

if "!NAV_CHOICE!"=="7" (
    if "!SHOW_ACTIVE_ONLY!"=="0" (set "SHOW_ACTIVE_ONLY=1") else (set "SHOW_ACTIVE_ONLY=0")
    goto EXPLORER_REBUILD_LIST
)
if "!NAV_CHOICE!"=="6" goto MAIN_MENU
if "!NAV_CHOICE!"=="5" goto EXPLORER_ACTION_INIT
if "!NAV_CHOICE!"=="4" (
    set /a current_index+=10
    if !current_index! GTR !total_apps! set current_index=!total_apps!
    goto EXPLORER_RENDER
)
if "!NAV_CHOICE!"=="3" (
    set /a current_index-=10
    if !current_index! LSS 1 set current_index=1
    goto EXPLORER_RENDER
)
if "!NAV_CHOICE!"=="2" (
    if !current_index! LSS !total_apps! set /a current_index+=1
    goto EXPLORER_RENDER
)
if "!NAV_CHOICE!"=="1" (
    if !current_index! GTR 1 set /a current_index-=1
    goto EXPLORER_RENDER
)
goto EXPLORER_RENDER

:EXPLORER_ACTION_INIT
set "sel_pkg=!app_pkg[%current_index%]!"
call :GET_APP_NAME !sel_pkg!
set "sel_lbl=!APP_LABEL!"

:EXPLORER_ACTION_LOOP
call :CHECK_APP_STATE !sel_pkg!

cls
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_CYAN%  APP MANAGEMENT PANEL                                                                                               %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BOLD%App Name:%RESET%    %TXT_WHT%!sel_lbl!%RESET%
echo  %BOLD%Package ID:%RESET%  %TXT_WHT%!sel_pkg!%RESET%
echo  %BOLD%App Status:%RESET%  !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  %TXT_GRN%[F]%RESET% Safe Remove (Uninstall for User 0 - Recommended for HyperOS)
echo  %TXT_CYAN%[R]%RESET% Unfreeze / Restore App
echo  %TXT_YEL%[B]%RESET% Back to App List
echo.
echo  Press %TXT_GRN%[F]%RESET%, %TXT_CYAN%[R]%RESET%, or %TXT_YEL%[B]%RESET%ack...

choice /c FRB /n >nul
set "ACT_CHOICE=!errorlevel!"
if "!ACT_CHOICE!"=="3" goto EXPLORER_REBUILD_LIST

echo.
if "!ACT_CHOICE!"=="1" (
    echo  %TXT_GRAY%Executing: pm uninstall -k --user 0 !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell pm uninstall -k --user 0 !sel_pkg! >nul 2>&1
    echo  %TXT_GRN%[OK] Safe Uninstall command sent.%RESET%
    echo  %time% ^| UNINSTALL-K ^| !sel_pkg! ^| Interactive Explorer >> "%LOGFILE%"
)
if "!ACT_CHOICE!"=="2" (
    echo  %TXT_GRAY%Executing: cmd package install-existing !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing !sel_pkg! >nul 2>&1
    echo  %TXT_GRAY%Executing: pm enable !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell pm enable !sel_pkg! >nul 2>&1
    echo  %TXT_GRN%[OK] App Restored / Unfrozen.%RESET%
    echo  %time% ^| RESTORE ^| !sel_pkg! ^| Interactive Explorer >> "%LOGFILE%"
)
call :CACHE_DEVICE_STATE
timeout /t 1 >nul
goto EXPLORER_ACTION_LOOP

:: ===============================================================================================
::  STANDARD DEBLOAT: STEP 2 & JOYOSE LOGIC
:: ===============================================================================================
:MODE_SELECT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  STEP 2: SELECT OPERATION MODE%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  Please select your preferred debloat method:
echo.
echo  %TXT_GRN%[S]%RESET%afe Remove / Freeze %TXT_GRAY%(Highly Recommended for HyperOS)%RESET%
echo  %TXT_GRAY%-------------------------------------------------%RESET%
echo  Uses "uninstall -k --user 0" to bypass HyperOS SecurityExceptions.
echo.
echo  %TXT_CYAN%[R]%RESET%estore %TXT_GRAY%(Recovery Mode)%RESET%
echo  %TXT_GRAY%-----------------------%RESET%
echo  Re-enables frozen apps or reinstalls safely removed apps.
echo.
echo  Press %TXT_GRN%[S]%RESET% to Safe Remove, or %TXT_CYAN%[R]%RESET% to Restore...

choice /c SR /n >nul
if errorlevel 2 (
    set "CMD_ACTION=RESTORE"
    set "MODE_NAME=RESTORE"
    set "MODE_VERB=Restore"
    set "LOG_MODE=RESTORED"
    set "apps_p4=!apps_p4! !apps_restore_only!"
) else (
    set "CMD_ACTION=pm uninstall -k --user 0"
    set "MODE_NAME=SAFE_REMOVE"
    set "MODE_VERB=Safe Remove"
    set "LOG_MODE=REMOVED_USER_0"
    
    :: Handle Joyose dynamically if in Debloat Mode
    if /I "!JOYOSE_ACTION!"=="ASK" (
        cls
        echo.
        echo  %TXT_GRAY%====================================================================================================================%RESET%
        echo  %BG_YEL%  JOYOSE THERMAL MANAGEMENT                                                                                          %RESET%
        echo  %TXT_GRAY%====================================================================================================================%RESET%
        echo.
        echo  The %TXT_WHT%com.xiaomi.joyose%RESET% app manages thermal components in the system.
        echo  %TXT_YEL%WARNING:%RESET% It may be required in some low-end and mid-end devices to prevent overheating.
        echo  If you want to turn it off, do it wisely. If you experience throttling, restore it later.
        echo.
        echo  Do you want to safely remove Joyose?
        echo  %TXT_RED%[Y]%RESET%es - Remove it   %TXT_GRN%[N]%RESET%o - Keep it safe
        choice /c YN /n >nul
        if errorlevel 2 (
            echo  -^> %TXT_GRN%Joyose will be kept.%RESET%
        ) else (
            set "apps_p1=com.xiaomi.joyose !apps_p1!"
            echo  -^> %TXT_RED%Joyose added to removal queue.%RESET%
        )
        timeout /t 3 >nul
    ) else if /I "!JOYOSE_ACTION!"=="REMOVE" (
        set "apps_p1=com.xiaomi.joyose !apps_p1!"
    )
)

:PREFERENCES_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  STEP 3: PREFERENCES ^& PREVIEW%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%[1] Smart Filtering ^(Context-Aware Auto-Skip^)%RESET%
echo      Automatically skips apps that are already in the target state.
echo.
echo  Press %TXT_GRN%[Y]%RESET%es to Enable or %TXT_RED%[N]%RESET%o to Disable...

choice /c YN /n >nul
if errorlevel 2 (
    set "SKIP_NOT_INSTALLED=0"
    echo  -^> %TXT_RED%Smart Filtering Disabled.%RESET%
) else (
    set "SKIP_NOT_INSTALLED=1"
    echo  -^> %TXT_GRN%Smart Filtering Enabled.%RESET%
)

echo.
echo  %TXT_CYAN%[2] Debloat Collection Preview%RESET%
echo      Do you want to see the full list of apps that will be processed?
echo.
echo  Press %TXT_YEL%[Y]%RESET%es or %TXT_YEL%[N]%RESET%o...

choice /c YN /n >nul
if errorlevel 2 goto PHASE1_INIT

cls
echo.
echo  %BG_GRN%  SAFE LIST (PHASE 1)                                                                                               %RESET%
for %%a in (%apps_p1%) do echo   - %%a
echo.
echo  %BG_YEL%  ADVANCED LIST (PHASE 2)                                                                                           %RESET%
for %%a in (%apps_p2%) do echo   - %%a
echo.
echo  %BG_RED%  RISKY SYSTEM APPS (PHASE 3)                                                                                       %RESET%
for %%a in (%apps_p3%) do echo   - %%a
echo.
echo  %BG_MAG%  HIDDEN SYSTEM APPS (PHASE 4)                                                                                      %RESET%
for %%a in (%apps_p4%) do echo   - %%a
echo.
echo  %TXT_GRAY%  Press any key to begin processing...%RESET%
pause >nul

:: ===============================================================================================
::  PHASES
:: ===============================================================================================
:PHASE1_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 1/4 %TXT_GRN%^|%TXT_WHT% Ads, Analytics ^& Junk Services%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRN%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_GRN%[M]%RESET%anual Review %TXT_GRAY%(Recommended)%RESET%   %TXT_GRN%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto PHASE2_INIT
for %%p in (%apps_p1%) do (
    call :GET_APP_NAME %%p
    if "%P_CHOICE%"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "SAFE" ) else ( call :ASK_USER %%p "!APP_LABEL!" "SAFE" )
)

:PHASE2_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 2/4 %TXT_YEL%^|%TXT_WHT% User Tools ^& Features%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_YEL%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_YEL%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_YEL%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto PHASE3_INIT
for %%p in (%apps_p2%) do (
    call :GET_APP_NAME %%p
    if "%P_CHOICE%"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "CAUTION" ) else ( call :ASK_USER %%p "!APP_LABEL!" "CAUTION" )
)

:PHASE3_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 3/4 %TXT_RED%^|%TXT_WHT% Risky System Apps%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_RED%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_RED%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_RED%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto PHASE4_INIT
for %%p in (%apps_p3%) do (
    call :GET_APP_NAME %%p
    if "%P_CHOICE%"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "DANGER" ) else ( call :ASK_USER %%p "!APP_LABEL!" "DANGER" )
)

:PHASE4_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 4/4 %TXT_MAG%^|%TXT_WHT% Hidden System Apps%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_MAG%[A]%RESET%uto Process %TXT_RED%(Risky)%RESET%   %TXT_MAG%[M]%RESET%anual Review %TXT_GRN%(Recommended)%RESET%   %TXT_MAG%[S]%RESET%kip Phase
choice /c AMS /n >nul
set "P_CHOICE=%errorlevel%"
if "%P_CHOICE%"=="3" goto FINISH
for %%p in (%apps_p4%) do (
    call :GET_APP_NAME %%p
    if "%P_CHOICE%"=="1" ( call :EXECUTE_ACTION %%p "!APP_LABEL!" "HIDDEN" ) else ( call :ASK_USER %%p "!APP_LABEL!" "HIDDEN" )
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
echo  %TXT_GRAY%[System] Syncing ADB package state...%RESET%
!ADB_CMD! -s !TARGET_ID! shell pm list packages -u > "%temp%\adb_all.txt" 2>nul
!ADB_CMD! -s !TARGET_ID! shell pm list packages -e > "%temp%\adb_active.txt" 2>nul
!ADB_CMD! -s !TARGET_ID! shell pm list packages -d > "%temp%\adb_disabled.txt" 2>nul
goto :eof

:PRINT_MANUAL_HEADER
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  !THEME_BG!  APP PROCESSING                                                                                                     %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
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
    if !errorlevel! equ 0 (
        set "APP_STATE=Installed (Active)"
        set "APP_STATE_COLOR=%TXT_GRN%"
    )
    findstr /I /C:"package:!CHK_PKG!" "%temp%\adb_disabled.txt" >nul 2>&1
    if !errorlevel! equ 0 (
        set "APP_STATE=Frozen (Disabled)"
        set "APP_STATE_COLOR=%TXT_CYAN%"
    )
)
goto :eof

:EXECUTE_ACTION
set "pkg=%~1"
set "lbl=%~2"
set "type=%~3"
if "%type%"=="SAFE" (set "THEME_BG=%BG_GRN%")
if "%type%"=="CAUTION" (set "THEME_BG=%BG_YEL%")
if "%type%"=="DANGER" (set "THEME_BG=%BG_RED%")
if "%type%"=="HIDDEN" (set "THEME_BG=%BG_MAG%")

call :CHECK_APP_STATE %pkg%
if "!SKIP_NOT_INSTALLED!"=="1" (
    set "SHOULD_SKIP=0"
    if "!MODE_NAME!"=="RESTORE" (
        if "!APP_STATE!"=="Installed (Active)" set "SHOULD_SKIP=1"
    ) else (
        if "!APP_STATE!"=="Not Installed / Removed" set "SHOULD_SKIP=1"
        if "!APP_STATE!"=="Uninstalled (User 0)" set "SHOULD_SKIP=1"
        if "!APP_STATE!"=="Frozen (Disabled)" set "SHOULD_SKIP=1"
    )
    if "!SHOULD_SKIP!"=="1" goto :eof
)

echo  Processing: %TXT_WHT%!lbl!%RESET% ^(!pkg!^)
if "!MODE_NAME!"=="RESTORE" (
    !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing %pkg% >nul 2>&1
    !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1
) else (
    !ADB_CMD! -s !TARGET_ID! shell %CMD_ACTION% %pkg% >nul 2>&1
)
echo  %TXT_GRN%[OK] Executed.%RESET%
goto :eof

:ASK_USER
set "pkg=%~1"
set "lbl=%~2"
set "type=%~3"
if "%type%"=="SAFE" (set "THEME_BG=%BG_GRN%")
if "%type%"=="CAUTION" (set "THEME_BG=%BG_YEL%")
if "%type%"=="DANGER" (set "THEME_BG=%BG_RED%")
if "%type%"=="HIDDEN" (set "THEME_BG=%BG_MAG%")

call :CHECK_APP_STATE %pkg%
if "!SKIP_NOT_INSTALLED!"=="1" (
    set "SHOULD_SKIP=0"
    if "!MODE_NAME!"=="RESTORE" (
        if "!APP_STATE!"=="Installed (Active)" set "SHOULD_SKIP=1"
    ) else (
        if "!APP_STATE!"=="Not Installed / Removed" set "SHOULD_SKIP=1"
        if "!APP_STATE!"=="Uninstalled (User 0)" set "SHOULD_SKIP=1"
        if "!APP_STATE!"=="Frozen (Disabled)" set "SHOULD_SKIP=1"
    )
    if "!SHOULD_SKIP!"=="1" goto :eof
)

set "CHOICES=YNE"
set "PROMPT_TEXT=>> %MODE_NAME%?  %TXT_GRN%[Y]%RESET%es - %MODE_VERB%   %TXT_RED%[N]%RESET%o - Skip   %TXT_CYAN%[E]%RESET%xit"
if "!APP_STATE!"=="Frozen (Disabled)" (
    set "CHOICES=YNEU"
    set "PROMPT_TEXT=>> %MODE_NAME%?  %TXT_GRN%[Y]%RESET%es - %MODE_VERB%   %TXT_RED%[N]%RESET%o - Skip   %TXT_YEL%[U]%RESET%nfreeze   %TXT_CYAN%[E]%RESET%xit"
)

cls
call :PRINT_MANUAL_HEADER
echo  %BOLD%!lbl!%RESET% ^(%pkg%^)
echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  !PROMPT_TEXT!

choice /c !CHOICES! /n >nul
if errorlevel 4 (
    !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1
    timeout /t 1 >nul
    goto :eof
)
if errorlevel 3 goto FINISH
if errorlevel 2 goto :eof
call :EXECUTE_ACTION %pkg% "!lbl!" "MANUAL_CALL"
goto :eof

:GET_APP_NAME
set "pkg=%~1"
set "APP_LABEL=%~1"
:: --- Just adding Joyose explicitly since we removed it from the hardcoded list
if "%pkg%"=="com.xiaomi.joyose" set "APP_LABEL=Joyose (Thermal/Performance Manager)"
if "%pkg%"=="com.miui.analytics" set "APP_LABEL=MIUI Analytics (Ad Tracking)"
:: ... (The rest of your GET_APP_NAME conditionals remain identical here)
goto :eof