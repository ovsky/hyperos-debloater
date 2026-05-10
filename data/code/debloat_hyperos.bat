@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=50
title Xiaomi HyperOS Debloat Commander v17.4

:: Physically navigate to resolve bulletproof paths
cd /d "%~dp0"
cd ..\..
set "ROOT_DIR=%cd%"
set "CONFIG_PATH=%cd%\data\config\config.json"
set "LOGS_DIR=%cd%\logs"
cd /d "%~dp0"

:: Validate JSON Integrity
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ERROR: "%CONFIG_PATH%" contains syntax errors or is missing.
    pause & exit
)

:: Secure JSON to Batch variable extraction via temporary script
set "TEMP_VARS=%temp%\hyperos_vars_%RANDOM%.cmd"
powershell -NoProfile -Command "$c = Get-Content -Raw '%CONFIG_PATH%' | ConvertFrom-Json; $out = @(); $out += 'set \"JOYOSE_ACTION=' + $c.settings.joyoseAction + '\"'; $out += 'set \"SKIP_NOT_INSTALLED=' + [int][bool]$c.settings.smartFiltering + '\"'; $out += 'set \"SHOW_PREVIEW=' + [int][bool]$c.settings.showPreview + '\"'; $out += 'set \"LOG_ENABLED=' + [int][bool]$c.settings.logToText + '\"'; $out += 'set \"ADB_PATH=' + $c.settings.defaultAdbPath + '\"'; $out += 'set \"apps_p1=' + ($c.phases.phase1_safe -join ' ') + '\"'; $out += 'set \"apps_p2=' + ($c.phases.phase2_advanced -join ' ') + '\"'; $out += 'set \"apps_p3=' + ($c.phases.phase3_risky -join ' ') + '\"'; $out += 'set \"apps_p4=' + ($c.phases.phase4_hidden -join ' ') + '\"'; $out += 'set \"apps_restore_only=' + ($c.phases.restore_only -join ' ') + '\"'; $out | Set-Content -Path '%TEMP_VARS%' -Encoding ASCII"
call "%TEMP_VARS%"
del "%TEMP_VARS%"

:: ADB Setup
set "ADB_CMD=!ADB_PATH!"
if exist "%ROOT_DIR%\!ADB_PATH!" set "ADB_CMD="%ROOT_DIR%\!ADB_PATH!""

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
    set "LOGFILE=%LOGS_DIR%\Debloat_Log_!SAFE_DT!_!SAFE_TM!.txt"
    
    echo [LOG STARTED] > "!LOGFILE!"
    echo Target OS: Xiaomi HyperOS >> "!LOGFILE!"
    echo Date: %date% %time% >> "!LOGFILE!"
    echo -------------------------------------------------------- >> "!LOGFILE!"
)

:: ===============================================================================================
::  STARTUP DASHBOARD
:: ===============================================================================================
color 0B
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT COMMANDER %TXT_CYAN%-%TXT_WHT% System Ready%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                      %RESET%
!ADB_CMD! start-server >nul 2>&1

:CHECK_DEVICES
set count=0
for /f "skip=1 tokens=1,*" %%a in ('!ADB_CMD! devices -l') do (
    if not "%%a" == "" (
        set /a count+=1
        set "device[!count!]=%%a"
        for /f "tokens=*" %%m in ('!ADB_CMD! -s %%a shell getprop ro.product.model') do set "model[!count!]=%%m"
    )
)

if %count%==0 (
    echo  %BG_RED%  ERROR: CONNECTION FAILED                                                                                          %RESET%
    echo  %TXT_RED%  [!]%RESET% No device detected. Check USB Debugging.
    pause >nul
    cls
    goto CHECK_DEVICES
)

set "TARGET_ID=!device[1]!"
set "TARGET_MODEL=!model[1]!"
echo  %TXT_GRN%  [v]%RESET% Connected Model: %TXT_WHT%!TARGET_MODEL!%RESET%
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
echo  %TXT_CYAN%[2] Interactive App Explorer%RESET%
echo  %TXT_YEL%[3] Refresh Device Cache%RESET%
echo  %TXT_RED%[E] Return to Manager%RESET%
echo.
echo  Press %TXT_GRN%[1]%RESET%, %TXT_CYAN%[2]%RESET%, %TXT_YEL%[3]%RESET%, or %TXT_RED%[E]%RESET%xit...

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
set "all_db_apps=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only% com.xiaomi.joyose"

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
echo  %TXT_GRN%[F]%RESET% Safe Remove   %TXT_CYAN%[R]%RESET% Unfreeze / Restore   %TXT_YEL%[B]%RESET%ack
choice /c FRB /n >nul
if "!errorlevel!"=="3" goto EXPLORER_REBUILD_LIST
if "!errorlevel!"=="1" (
    !ADB_CMD! -s !TARGET_ID! shell pm uninstall -k --user 0 !sel_pkg! >nul 2>&1
    echo %time% ^| UNINSTALL ^| !sel_pkg! >> "!LOGFILE!"
)
if "!errorlevel!"=="2" (
    !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing !sel_pkg! >nul 2>&1
    !ADB_CMD! -s !TARGET_ID! shell pm enable !sel_pkg! >nul 2>&1
    echo %time% ^| RESTORE ^| !sel_pkg! >> "!LOGFILE!"
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
echo  %TXT_GRN%[S]%RESET%afe Remove / Freeze %TXT_GRAY%(Highly Recommended for HyperOS)%RESET%
echo  %TXT_CYAN%[R]%RESET%estore %TXT_GRAY%(Recovery Mode)%RESET%
echo.
choice /c SR /n >nul
if errorlevel 2 (
    set "CMD_ACTION=RESTORE"
    set "MODE_NAME=RESTORE"
    set "MODE_VERB=Restore"
    set "apps_p4=!apps_p4! !apps_restore_only!"
) else (
    set "CMD_ACTION=pm uninstall -k --user 0"
    set "MODE_NAME=SAFE_REMOVE"
    set "MODE_VERB=Safe Remove"
    
    :: Handle Joyose via JSON setting
    if /I "!JOYOSE_ACTION!"=="ASK" (
        cls
        echo.
        echo  %BG_YEL%  JOYOSE THERMAL MANAGEMENT                                                                                          %RESET%
        echo  %TXT_WHT%com.xiaomi.joyose%RESET% manages thermal components. Needed on some devices to prevent overheating.
        echo.
        echo  Do you want to safely remove Joyose?
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
)

echo  Processing: %TXT_WHT%!lbl!%RESET% ^(!pkg!^)
if "!MODE_NAME!"=="RESTORE" (
    !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing %pkg% >nul 2>&1
    !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1
) else ( !ADB_CMD! -s !TARGET_ID! shell %CMD_ACTION% %pkg% >nul 2>&1 )
echo %time% ^| EXECUTE ^| %pkg% >> "!LOGFILE!"
goto :eof

:ASK_USER
set "pkg=%~1"
set "lbl=%~2"
call :CHECK_APP_STATE %pkg%
if "!SKIP_NOT_INSTALLED!"=="1" (
    if "!MODE_NAME!"=="RESTORE" ( if "!APP_STATE!"=="Installed (Active)" goto :eof )
    if "!MODE_NAME!"=="SAFE_REMOVE" ( if "!APP_STATE!"=="Not Installed / Removed" goto :eof & if "!APP_STATE!"=="Uninstalled (User 0)" goto :eof & if "!APP_STATE!"=="Frozen (Disabled)" goto :eof )
)

set "CHOICES=YNE"
set "P_TXT=>> %MODE_VERB%?  %TXT_GRN%[Y]%RESET%es   %TXT_RED%[N]%RESET%o   %TXT_CYAN%[E]%RESET%xit"
if "!APP_STATE!"=="Frozen (Disabled)" ( set "CHOICES=YNEU" & set "P_TXT=>> %MODE_VERB%?  %TXT_GRN%[Y]%RESET%es   %TXT_RED%[N]%RESET%o   %TXT_YEL%[U]%RESET%nfreeze   %TXT_CYAN%[E]%RESET%xit" )

cls
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%!lbl!%RESET% ^(%pkg%^)
echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  !P_TXT!

choice /c !CHOICES! /n >nul
if errorlevel 4 ( !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1 & goto :eof )
if errorlevel 3 goto FINISH
if errorlevel 2 goto :eof
call :EXECUTE_ACTION %pkg% "!lbl!" "MANUAL"
goto :eof

:GET_APP_NAME
set "pkg=%~1"
set "APP_LABEL=%~1"
if "%pkg%"=="com.xiaomi.joyose" set "APP_LABEL=Joyose (Thermal Manager)"
if "%pkg%"=="com.miui.analytics" set "APP_LABEL=MIUI Analytics"
if "%pkg%"=="com.miui.systemAdSolution" set "APP_LABEL=MIUI System Ad Solution"
if "%pkg%"=="com.miui.msa.global" set "APP_LABEL=MSA (Main System Ads Service)"
if "%pkg%"=="com.miui.daemon" set "APP_LABEL=MIUI Daemon (Data Collection)"
if "%pkg%"=="com.xiaomi.discover" set "APP_LABEL=Xiaomi Discover (Ads/Recommendations)"
if "%pkg%"=="com.xiaomi.ab" set "APP_LABEL=Xiaomi AB (Ads)"
if "%pkg%"=="com.facebook.appmanager" set "APP_LABEL=Facebook App Manager"
if "%pkg%"=="com.facebook.services" set "APP_LABEL=Facebook Services"
if "%pkg%"=="com.facebook.system" set "APP_LABEL=Facebook System Framework"
if "%pkg%"=="com.facebook.katana" set "APP_LABEL=Facebook App (Pre-installed)"
if "%pkg%"=="com.mi.global.bbs" set "APP_LABEL=Xiaomi Community"
if "%pkg%"=="com.miui.cloudservice.sysbase" set "APP_LABEL=Xiaomi Cloud Service Base"
if "%pkg%"=="com.miui.cleanmaster" set "APP_LABEL=Clean Master (Ads/Junk Cleaner)"
if "%pkg%"=="com.miui.miservice" set "APP_LABEL=Mi Services (Support/Ads)"
if "%pkg%"=="com.miui.touchassistant" set "APP_LABEL=Quick Ball (Touch Assistant)"
if "%pkg%"=="com.miui.hybrid" set "APP_LABEL=Quick Apps Service"
if "%pkg%"=="com.miui.hybrid.accessory" set "APP_LABEL=Quick Apps Accessory"
if "%pkg%"=="com.miui.translation.kingsoft" set "APP_LABEL=Kingsoft Translation"
if "%pkg%"=="com.miui.translation.xmcloud" set "APP_LABEL=Xiaomi Cloud Translation"
if "%pkg%"=="com.miui.translationservice" set "APP_LABEL=Translation Service"
if "%pkg%"=="com.miui.cit" set "APP_LABEL=CIT (Hardware Test)"
if "%pkg%"=="com.miui.wmsvc" set "APP_LABEL=WM Service (Cloud Backups)"
if "%pkg%"=="com.miui.userguide" set "APP_LABEL=User Guide"
if "%pkg%"=="com.miui.backup" set "APP_LABEL=MIUI Backup"
if "%pkg%"=="com.xiaomi.xmsf" set "APP_LABEL=Xiaomi Service Framework"
if "%pkg%"=="com.mi.global.shop" set "APP_LABEL=Xiaomi Store"
if "%pkg%"=="com.miui.nextpay" set "APP_LABEL=Mi Pay Framework"
if "%pkg%"=="com.miui.tsmclient" set "APP_LABEL=Mi Pay Client"
if "%pkg%"=="com.miui.greenguard" set "APP_LABEL=Family Link / Kids Mode"
if "%pkg%"=="com.xiaomi.gamecenter" set "APP_LABEL=Xiaomi Game Center"
if "%pkg%"=="com.xiaomi.gamecenter.sdk.service" set "APP_LABEL=Xiaomi Game SDK"
if "%pkg%"=="com.miui.uireporter" set "APP_LABEL=MIUI UI Analytics"
if "%pkg%"=="com.miui.securityadd" set "APP_LABEL=MIUI Security Addons"
if "%pkg%"=="com.baidu.input_mi" set "APP_LABEL=Baidu Keyboard (Chinese)"
if "%pkg%"=="com.iflytek.inputmethod.miui" set "APP_LABEL=iFlyTek Keyboard"
if "%pkg%"=="com.sohu.inputmethod.sogou.xiaomi" set "APP_LABEL=Sogou Keyboard"
if "%pkg%"=="com.tencent.soter.soterserver" set "APP_LABEL=Tencent Soter Framework"
if "%pkg%"=="com.bsp.catchlog" set "APP_LABEL=BSP Catch Log"
if "%pkg%"=="com.xiaomi.security.onetrack" set "APP_LABEL=Xiaomi OneTrack (Telemetry)"
if "%pkg%"=="com.wapi.wapicertmanage" set "APP_LABEL=WAPI Certificate Manage"
if "%pkg%"=="com.miui.newmidrive" set "APP_LABEL=Xiaomi Cloud Drive"
if "%pkg%"=="com.xiaomi.aireco" set "APP_LABEL=Xiaomi AI Recommendations"
if "%pkg%"=="com.qti.qualcomm.deviceinfo" set "APP_LABEL=Qualcomm Device Info"
if "%pkg%"=="com.unionpay.tsmservice.mi" set "APP_LABEL=UnionPay TSM Service"
if "%pkg%"=="com.miui.guardprovider" set "APP_LABEL=MIUI Guard Provider"
if "%pkg%"=="com.miui.powerinsight" set "APP_LABEL=MIUI Power Insight"
if "%pkg%"=="com.miui.yellowpage" set "APP_LABEL=MIUI Yellow Pages"
if "%pkg%"=="com.xiaomi.pass" set "APP_LABEL=Xiaomi Pass"
if "%pkg%"=="com.mipay.wallet" set "APP_LABEL=Xiaomi Wallet"
if "%pkg%"=="com.miui.compass" set "APP_LABEL=Mi Compass"
if "%pkg%"=="com.miui.weather2" set "APP_LABEL=Mi Weather"
if "%pkg%"=="com.miui.notes" set "APP_LABEL=Mi Notes"
if "%pkg%"=="com.miui.calculator" set "APP_LABEL=Mi Calculator"
if "%pkg%"=="com.miui.videoplayer" set "APP_LABEL=Mi Video"
if "%pkg%"=="com.miui.player" set "APP_LABEL=Mi Music"
if "%pkg%"=="com.xiaomi.glgm" set "APP_LABEL=Xiaomi Games"
if "%pkg%"=="com.miui.gallery" set "APP_LABEL=Mi Gallery"
if "%pkg%"=="com.miui.fmservice" set "APP_LABEL=FM Radio Service"
if "%pkg%"=="com.miui.fm" set "APP_LABEL=FM Radio App"
if "%pkg%"=="com.android.stk" set "APP_LABEL=SIM Toolkit"
if "%pkg%"=="com.xiaomi.midrop" set "APP_LABEL=Mi Drop (Share)"
if "%pkg%"=="com.xiaomi.payment" set "APP_LABEL=Mi Pay / Wallet"
if "%pkg%"=="com.xiaomi.vipaccount" set "APP_LABEL=Xiaomi VIP Account"
if "%pkg%"=="com.duokan.phone.remotecontroller" set "APP_LABEL=Mi Remote"
if "%pkg%"=="com.xiaomi.smarthome" set "APP_LABEL=Xiaomi Home"
if "%pkg%"=="com.android.calendar" set "APP_LABEL=Xiaomi Calendar"
if "%pkg%"=="com.miui.calendar" set "APP_LABEL=Xiaomi Calendar (Alt)"
if "%pkg%"=="com.android.deskclock" set "APP_LABEL=Xiaomi Clock"
if "%pkg%"=="com.android.providers.downloads.ui" set "APP_LABEL=Downloads App"
if "%pkg%"=="com.mi.android.globalFileexplorer" set "APP_LABEL=File Manager"
if "%pkg%"=="com.android.fileexplorer" set "APP_LABEL=File Manager (Alt)"
if "%pkg%"=="com.android.soundrecorder" set "APP_LABEL=Sound Recorder"
if "%pkg%"=="com.android.email" set "APP_LABEL=Xiaomi Email App"
if "%pkg%"=="com.miui.screenrecorder" set "APP_LABEL=Screen Recorder"
if "%pkg%"=="com.miui.huanji" set "APP_LABEL=Mi Mover"
if "%pkg%"=="com.android.browser" set "APP_LABEL=Mi Browser"
if "%pkg%"=="com.miui.browser" set "APP_LABEL=Mi Browser (Alt)"
if "%pkg%"=="cn.wps.moffice_eng.xiaomi.lite" set "APP_LABEL=Mi Doc Viewer (WPS)"
if "%pkg%"=="com.miui.qr" set "APP_LABEL=Xiaomi QR Scanner"
if "%pkg%"=="com.miui.mediaviewer" set "APP_LABEL=MIUI Media Viewer"
if "%pkg%"=="com.miui.mediaeditor" set "APP_LABEL=MIUI Gallery Editor"
if "%pkg%"=="com.miui.personalassistant" set "APP_LABEL=App Vault (Smart Assistant)"
if "%pkg%"=="com.miui.appvault" set "APP_LABEL=App Vault (Core)"
if "%pkg%"=="com.miui.themestore" set "APP_LABEL=Themes Store"
if "%pkg%"=="com.android.thememanager" set "APP_LABEL=Themes Store (Alt 1)"
if "%pkg%"=="com.xiaomi.thememanager" set "APP_LABEL=Themes Store (Alt 2)"
if "%pkg%"=="com.miui.findmy" set "APP_LABEL=Find Device (HyperOS)"
if "%pkg%"=="com.xiaomi.finddevice" set "APP_LABEL=Find Device (Legacy)"
if "%pkg%"=="com.xiaomi.scanner" set "APP_LABEL=AI Scanner (HyperOS)"
if "%pkg%"=="com.miui.scanner" set "APP_LABEL=Mi Scanner (Legacy)"
if "%pkg%"=="com.xiaomi.market" set "APP_LABEL=GetApps (Xiaomi Market)"
if "%pkg%"=="com.xiaomi.mipicks" set "APP_LABEL=GetApps (Alt)"
if "%pkg%"=="com.miui.securitycenter" set "APP_LABEL=Security Center"
if "%pkg%"=="com.xiaomi.account" set "APP_LABEL=Xiaomi Account Framework"
if "%pkg%"=="com.miui.cloudservice" set "APP_LABEL=Xiaomi Cloud Service"
if "%pkg%"=="com.miui.micloudsync" set "APP_LABEL=Xiaomi Cloud Sync"
if "%pkg%"=="com.miui.cloudbackup" set "APP_LABEL=Xiaomi Cloud Backup"
if "%pkg%"=="com.xiaomi.roaming" set "APP_LABEL=Mi Roaming"
if "%pkg%"=="com.miui.roaming" set "APP_LABEL=Mi Roaming (Alt)"
if "%pkg%"=="com.miui.aod" set "APP_LABEL=Always-on Display"
if "%pkg%"=="com.xiaomi.hypercomm" set "APP_LABEL=HyperOS Interconnect"
if "%pkg%"=="com.miui.audiomonitor" set "APP_LABEL=Audio Monitor Service"
if "%pkg%"=="com.miui.voiceassistProxy" set "APP_LABEL=Voice Assist Proxy"
if "%pkg%"=="com.xiaomi.aiasst.service" set "APP_LABEL=Xiaomi AI Assistant Service"
if "%pkg%"=="com.xiaomi.aiasst.vision" set "APP_LABEL=Xiaomi AI Vision"
if "%pkg%"=="com.xiaomi.mibrain.speech" set "APP_LABEL=Xiaomi AI Speech Engine"
if "%pkg%"=="com.xiaomi.metoknlp" set "APP_LABEL=Xiaomi Location Services"
if "%pkg%"=="com.android.dreams.basic" set "APP_LABEL=Basic Daydreams"
if "%pkg%"=="com.android.dreams.phototable" set "APP_LABEL=Photo Table"
if "%pkg%"=="com.android.printspooler" set "APP_LABEL=Android Print Spooler"
if "%pkg%"=="com.android.bips" set "APP_LABEL=Default Print Service"
if "%pkg%"=="com.android.bookmarkprovider" set "APP_LABEL=Bookmark Provider"
if "%pkg%"=="com.android.traceur" set "APP_LABEL=System Tracing"
if "%pkg%"=="com.miui.contentextension" set "APP_LABEL=MIUI Content Extension"
if "%pkg%"=="com.miui.carlink" set "APP_LABEL=MIUI CarLink"
if "%pkg%"=="com.miui.thirdappassistant" set "APP_LABEL=Third App Assistant"
if "%pkg%"=="com.xiaomi.aicr" set "APP_LABEL=Xiaomi AICR"
if "%pkg%"=="com.miui.misightservice" set "APP_LABEL=Mi Sight Service"
if "%pkg%"=="com.xiaomi.barrage" set "APP_LABEL=Xiaomi Barrage"
if "%pkg%"=="com.xiaomi.mirror" set "APP_LABEL=Xiaomi Mirror"
if "%pkg%"=="com.miui.voiceassistoverlay" set "APP_LABEL=Voice Assist Overlay"
goto :eof