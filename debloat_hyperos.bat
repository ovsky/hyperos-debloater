@echo off
setlocal EnableDelayedExpansion
mode con: cols=120 lines=50
title Xiaomi HyperOS Debloat Commander v17.0
cd /d "%~dp0"

:: Ensure ADB command is absolute if present in folder, else rely on PATH
set "ADB_CMD=adb"
if exist "%~dp0adb.exe" set "ADB_CMD="%~dp0adb.exe""

:: ===============================================================================================
::  CONFIGURATION & APP DEFINITIONS
:: ===============================================================================================

:: 1. PHASE 1: SAFE LIST (Ads, Analytics, Background Stubs, Junk Services)
set "apps_p1=com.miui.analytics com.miui.msa.global com.miui.daemon com.xiaomi.joyose com.facebook.appmanager com.facebook.services com.facebook.system com.facebook.katana com.miui.cleanmaster com.miui.miservice com.miui.touchassistant com.miui.hybrid com.miui.hybrid.accessory com.xiaomi.discover com.xiaomi.ab com.miui.cit com.miui.wmsvc com.miui.userguide com.miui.backup com.xiaomi.xmsf com.mi.global.bbs com.mi.global.shop com.miui.nextpay com.miui.tsmclient com.miui.greenguard com.xiaomi.gamecenter.sdk.service com.miui.uireporter com.miui.securityadd com.baidu.input_mi com.iflytek.inputmethod.miui com.sohu.inputmethod.sogou.xiaomi com.tencent.soter.soterserver com.bsp.catchlog com.xiaomi.security.onetrack com.wapi.wapicertmanage com.miui.newmidrive com.xiaomi.aireco com.qti.qualcomm.deviceinfo com.unionpay.tsmservice.mi com.miui.guardprovider com.miui.powerinsight"

:: 2. PHASE 2: ADVANCED LIST (User-Facing Apps)
set "apps_p2=com.miui.compass com.miui.weather2 com.miui.notes com.miui.calculator com.miui.videoplayer com.miui.player com.xiaomi.glgm com.miui.gallery com.xiaomi.midrop com.miui.fmservice com.miui.fm com.android.stk com.xiaomi.payment com.xiaomi.vipaccount com.duokan.phone.remotecontroller com.xiaomi.smarthome com.android.calendar com.miui.calendar com.android.deskclock com.android.providers.downloads.ui com.android.fileexplorer com.mi.android.globalFileexplorer com.android.soundrecorder com.android.email com.miui.screenrecorder com.miui.huanji com.android.browser com.miui.browser cn.wps.moffice_eng.xiaomi.lite com.miui.qr com.miui.mediaviewer com.miui.mediaeditor"

:: 3. PHASE 3: RISKY SYSTEM APPS (Requested by User)
set "apps_p3=com.miui.personalassistant com.miui.appvault com.miui.themestore com.android.thememanager com.xiaomi.thememanager com.miui.findmy com.xiaomi.finddevice com.xiaomi.scanner com.miui.scanner com.xiaomi.market com.xiaomi.mipicks com.miui.securitycenter com.xiaomi.account com.miui.cloudservice com.miui.micloudsync com.miui.cloudbackup com.xiaomi.roaming com.miui.roaming"

:: 4. PHASE 4: HIDDEN SYSTEM APPS (Canta Suggestions & HyperOS Background)
set "apps_p4=com.miui.aod com.xiaomi.hypercomm com.miui.audiomonitor com.miui.voiceassistProxy com.xiaomi.aiasst.service com.xiaomi.aiasst.vision com.xiaomi.mibrain.speech com.xiaomi.metoknlp com.android.dreams.basic com.android.dreams.phototable com.android.printspooler com.android.bips com.android.bookmarkprovider com.android.traceur com.miui.contentextension com.miui.carlink com.miui.thirdappassistant com.xiaomi.aicr com.miui.misightservice com.xiaomi.barrage com.xiaomi.mirror com.miui.voiceassistoverlay"

:: 5. RESTORE ONLY LIST (Apps excluded from Freeze/Uninstall to prevent bootloops, but kept for Restoration)
set "apps_restore_only=com.miui.extraphoto com.miui.face com.android.egg com.miui.freeform com.miui.mishare.connectivity com.miui.phrase com.miui.vsimcore com.miui.virtualsim"

:: 6. ANSI Colors Setup
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
set "RESET=%ESC%[0m"
set "BOLD=%ESC%[1m"

:: Solid Headers
set "BG_CYAN=%ESC%[46m%ESC%[30m"
set "BG_MAG=%ESC%[45m%ESC%[30m"
set "BG_GRN=%ESC%[42m%ESC%[30m"
set "BG_YEL=%ESC%[43m%ESC%[30m"
set "BG_RED=%ESC%[41m%ESC%[97m"

:: Text Colors
set "TXT_CYAN=%ESC%[96m"
set "TXT_GRN=%ESC%[92m"
set "TXT_YEL=%ESC%[93m"
set "TXT_RED=%ESC%[91m"
set "TXT_MAG=%ESC%[95m"
set "TXT_GRAY=%ESC%[90m"
set "TXT_WHT=%ESC%[97m"

:: 7. Safe Log File Setup (Fixes "Drive Specified" Crash)
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
echo  %BOLD%%TXT_WHT%  HYPEROS DEBLOAT COMMANDER %TXT_CYAN%-%TXT_WHT% v17.0 Ultimate %TXT_CYAN%-%TXT_WHT% System Ready%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%  [+]%TXT_WHT% Target OS:       Xiaomi HyperOS / MIUI (Android 13/14+)%RESET%
echo  %TXT_CYAN%  [+]%TXT_WHT% Database:        130+ Bloatware Packages Loaded (4 Phases)%RESET%
echo.
echo  %BG_CYAN%  STATUS: WAITING FOR DEVICE...                                                                                     %RESET%
!ADB_CMD! start-server >nul 2>&1

:: ===============================================================================================
::  STEP 1: DEVICE CONNECTION
:: ===============================================================================================
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

    :: Save Device info to Log
    echo Device Model: !TARGET_MODEL! >> "%LOGFILE%"
    echo Device ID: !TARGET_ID! >> "%LOGFILE%"
    echo -------------------------------------------------------- >> "%LOGFILE%"

    timeout /t 1 >nul
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

:: Save Device info to Log
echo Device Model: !TARGET_MODEL! >> "%LOGFILE%"
echo Device ID: !TARGET_ID! >> "%LOGFILE%"
echo -------------------------------------------------------- >> "%LOGFILE%"

echo.
echo  %TXT_GRN%  [+]%RESET% Selected: !TARGET_MODEL!
timeout /t 1 >nul

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
echo      Automated or guided debloating using the built-in database of 130+ known packages.
echo.
echo  %TXT_CYAN%[2] Interactive App Explorer (Filtered ^& Sorted)%RESET%
echo      Browse ONLY the bloatware apps currently installed/frozen on your device via
echo      an alphabetically sorted list, and freeze, uninstall, or restore them one by one.
echo.
echo  %TXT_RED%[E] Exit Commander%RESET%
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Press %TXT_GRN%[1]%RESET%, %TXT_CYAN%[2]%RESET%, or %TXT_RED%[E]%RESET%xit...

choice /c 12E /n >nul
if errorlevel 3 goto FINISH
if errorlevel 2 goto INTERACTIVE_EXPLORER_INIT
if errorlevel 1 goto MODE_SELECT

:: ===============================================================================================
::  INTERACTIVE EXPLORER (ADVANCED FUNCTIONALITY)
:: ===============================================================================================
:INTERACTIVE_EXPLORER_INIT
set "SHOW_ACTIVE_ONLY=0"
set "all_db_apps=%apps_p1% %apps_p2% %apps_p3% %apps_p4% %apps_restore_only%"

:EXPLORER_REBUILD_LIST
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_CYAN%  INTERACTIVE APP EXPLORER                                                                                          %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRAY%Filtering and sorting database apps against your device... Please wait...%RESET%

if exist "%temp%\matched_apps.txt" del "%temp%\matched_apps.txt"

if "!SHOW_ACTIVE_ONLY!"=="1" (
    !ADB_CMD! -s !TARGET_ID! shell pm list packages -e > "%temp%\device_apps.txt" 2>nul
) else (
    !ADB_CMD! -s !TARGET_ID! shell pm list packages -u > "%temp%\device_apps.txt" 2>nul
)

for %%p in (!all_db_apps!) do (
    findstr /I /C:"package:%%p" "%temp%\device_apps.txt" >nul 2>&1
    if !errorlevel! equ 0 (
        call :GET_APP_NAME %%p
        echo !APP_LABEL!^|%%p>> "%temp%\matched_apps.txt"
    )
)
if exist "%temp%\device_apps.txt" del "%temp%\device_apps.txt" >nul 2>&1

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
    echo  %BG_CYAN%  INTERACTIVE APP EXPLORER ^| App !current_index! of !total_apps! ^| Filter: ACTIVE APPS ONLY                                    %RESET%
) else (
    echo  %BG_CYAN%  INTERACTIVE APP EXPLORER ^| App !current_index! of !total_apps! ^| Filter: ALL DB APPS                                         %RESET%
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
    if "!SHOW_ACTIVE_ONLY!"=="0" (
        set "SHOW_ACTIVE_ONLY=1"
    ) else (
        set "SHOW_ACTIVE_ONLY=0"
    )
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
cls
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_CYAN%  APP MANAGEMENT PANEL                                                                                              %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_GRAY%Reading info about app: %TXT_WHT%!sel_lbl!%TXT_GRAY% ^(!sel_pkg!^)...%RESET%
call :CHECK_APP_STATE !sel_pkg!

cls
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BG_CYAN%  APP MANAGEMENT PANEL                                                                                              %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BOLD%App Name:%RESET%    %TXT_WHT%!sel_lbl!%RESET%
echo  %BOLD%Package ID:%RESET%  %TXT_WHT%!sel_pkg!%RESET%
echo  %BOLD%App Status:%RESET%  !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  %TXT_GRN%[F]%RESET% Freeze / Disable App
echo  %TXT_RED%[U]%RESET% Uninstall App for User 0
echo  %TXT_CYAN%[R]%RESET% Unfreeze / Restore App
echo  %TXT_YEL%[B]%RESET% Back to App List
echo.
echo  Press %TXT_GRN%[F]%RESET%, %TXT_RED%[U]%RESET%, %TXT_CYAN%[R]%RESET%, or %TXT_YEL%[B]%RESET%ack...

choice /c FURB /n >nul
set "ACT_CHOICE=!errorlevel!"
if "!ACT_CHOICE!"=="4" goto EXPLORER_REBUILD_LIST

echo.
if "!ACT_CHOICE!"=="1" (
    echo  %TXT_GRAY%Executing: pm disable-user --user 0 !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell pm disable-user --user 0 !sel_pkg! >nul 2>&1
    echo  %TXT_GRN%[OK] Freeze command sent.%RESET%
    echo  %time% ^| FREEZE ^| !sel_pkg! ^| Interactive Explorer >> "%LOGFILE%"
)
if "!ACT_CHOICE!"=="2" (
    echo  %TXT_GRAY%Executing: pm uninstall --user 0 !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell pm uninstall --user 0 !sel_pkg! >nul 2>&1
    echo  %TXT_GRN%[OK] Uninstall command sent.%RESET%
    echo  %time% ^| UNINSTALL ^| !sel_pkg! ^| Interactive Explorer >> "%LOGFILE%"
)
if "!ACT_CHOICE!"=="3" (
    echo  %TXT_GRAY%Executing: cmd package install-existing !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing !sel_pkg! >nul 2>&1
    echo  %TXT_GRAY%Executing: pm enable !sel_pkg!...%RESET%
    !ADB_CMD! -s !TARGET_ID! shell pm enable !sel_pkg! >nul 2>&1
    echo  %TXT_GRN%[OK] App Restored / Unfrozen.%RESET%
    echo  %time% ^| RESTORE ^| !sel_pkg! ^| Interactive Explorer >> "%LOGFILE%"
)
timeout /t 2 >nul
goto EXPLORER_ACTION_LOOP

:: ===============================================================================================
::  STANDARD DEBLOAT: STEP 2
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
echo  %TXT_GRN%[F]%RESET%reeze / Disable %TXT_GRAY%(Highly Recommended)%RESET%
echo  %TXT_GRAY%-------------------------------------%RESET%
echo  Apps are hidden but not deleted. This is the safest method.
echo  You can restore apps instantly with no data loss.
echo.
echo  %TXT_RED%[U]%RESET%ninstall %TXT_GRAY%(Destructive)%RESET%
echo  %TXT_GRAY%-----------------------%RESET%
echo  Completely removes the app for the current user.
echo  Restoration is difficult and requires command line tools.
echo.
echo  %TXT_CYAN%[R]%RESET%estore %TXT_GRAY%(Recovery Mode)%RESET%
echo  %TXT_GRAY%-----------------------%RESET%
echo  Re-enables frozen apps or reinstalls removed apps.
echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Press %TXT_GRN%[F]%RESET% to Freeze, %TXT_RED%[U]%RESET% to Uninstall, or %TXT_CYAN%[R]%RESET% to Restore...

choice /c FUR /n >nul
if errorlevel 3 (
    set "CMD_ACTION=RESTORE"
    set "MODE_NAME=RESTORE"
    set "MODE_VERB=Restore"
    set "LOG_MODE=RESTORED"
    set "apps_p4=!apps_p4! !apps_restore_only!"
) else if errorlevel 2 (
    set "CMD_ACTION=pm uninstall --user 0"
    set "MODE_NAME=UNINSTALL"
    set "MODE_VERB=Uninstall"
    set "LOG_MODE=UNINSTALLED"
) else (
    set "CMD_ACTION=pm disable-user --user 0"
    set "MODE_NAME=FREEZE"
    set "MODE_VERB=Freeze"
    set "LOG_MODE=FROZEN"
)
echo Mode Selected: %MODE_NAME% >> "%LOGFILE%"
echo -------------------------------------------------------- >> "%LOGFILE%"

:: ===============================================================================================
::  STANDARD DEBLOAT: STEP 3 (PREFERENCES)
:: ===============================================================================================
:PREFERENCES_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  STEP 3: PREFERENCES ^& PREVIEW%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %TXT_CYAN%[1] Live App State Checking%RESET%
echo      Queries the device in real-time to show if an app is Installed, Uninstalled, or Frozen.
echo      %TXT_GRN%Highly helpful, but can slow down the process slightly.%RESET%
echo.
echo  Press %TXT_GRN%[Y]%RESET%es to Enable or %TXT_RED%[N]%RESET%o to Disable...

choice /c YN /n >nul
if errorlevel 2 (
    set "DO_LIVE_CHECK=0"
    echo  -^> %TXT_RED%Live Checking Disabled.%RESET%
) else (
    set "DO_LIVE_CHECK=1"
    echo  -^> %TXT_GRN%Live Checking Enabled.%RESET%
)

echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo.
if "!DO_LIVE_CHECK!"=="1" (
    echo  %TXT_CYAN%[2] Smart Filtering ^(Context-Aware Auto-Skip^)%RESET%
    echo      Debloat Mode: Skips apps that are already uninstalled or frozen.
    echo      Restore Mode: Skips apps that are already active.
    echo.
    echo  Press %TXT_GRN%[Y]%RESET%es to Enable or %TXT_RED%[N]%RESET%o to Disable...
    choice /c YN /n >nul
    if !errorlevel! equ 2 (
        set "SKIP_NOT_INSTALLED=0"
        echo  -^> %TXT_RED%Smart Filtering Disabled.%RESET%
    ) else (
        set "SKIP_NOT_INSTALLED=1"
        echo  -^> %TXT_GRN%Smart Filtering Enabled.%RESET%
    )
) else (
    echo  %TXT_GRAY%[2] Smart Filtering ^(Context-Aware Auto-Skip^)%RESET%
    echo  %TXT_GRAY%    Debloat Mode: Skips apps that are already uninstalled or frozen.%RESET%
    echo  %TXT_GRAY%    Restore Mode: Skips apps that are already active.%RESET%
    echo.
    echo  %TXT_GRAY%    [!] Option unavailable. Requires "Live App State Checking" to be Enabled.%RESET%
    set "SKIP_NOT_INSTALLED=0"
)

echo.
echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo.
echo  %TXT_CYAN%[3] Debloat Collection Preview%RESET%
echo      Do you want to see the full list of apps that will be processed before we begin?
echo.
echo  %TXT_YEL%[Y]%RESET%es, show full list of apps to be processed.
echo  %TXT_YEL%[N]%RESET%o, skip preview and start immediately.
echo.
echo  Press %TXT_YEL%[Y]%RESET% or %TXT_YEL%[N]%RESET%...

choice /c YN /n >nul
if errorlevel 2 goto PHASE1_INIT

cls
echo.
echo  %BG_GRN%  SAFE LIST (PHASE 1)                                                                                               %RESET%
echo  %TXT_GRAY%  (Ads, Analytics, Services, Stubs)%RESET%
for %%a in (%apps_p1%) do echo   - %%a
echo.
echo  %BG_YEL%  ADVANCED LIST (PHASE 2)                                                                                           %RESET%
echo  %TXT_GRAY%  (User Apps: Gallery, Weather, Tools)%RESET%
for %%a in (%apps_p2%) do echo   - %%a
echo.
echo  %BG_RED%  RISKY SYSTEM APPS (PHASE 3)                                                                                       %RESET%
echo  %TXT_GRAY%  (HyperOS Core: App Vault, Find Device, Themes, Security, GetApps)%RESET%
for %%a in (%apps_p3%) do echo   - %%a
echo.
echo  %BG_MAG%  HIDDEN SYSTEM APPS (PHASE 4)                                                                                      %RESET%
echo  %TXT_GRAY%  (Background APIs and Hidden Telemetry)%RESET%
for %%a in (%apps_p4%) do echo   - %%a
echo.
echo  %TXT_GRAY%  Press any key to begin processing...%RESET%
pause >nul

:: ===============================================================================================
::  PHASE 1: SAFE APPS
:: ===============================================================================================
:PHASE1_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 1/4 %TXT_GRN%^|%TXT_WHT% Ads, Analytics ^& Junk Services%RESET%
echo  %TXT_GRAY%  Phase 1 of 4 in total%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BG_GRN%  SELECT MODE                                                                                                       %RESET%
echo.
echo  %TXT_GRN%[A]%RESET%uto Process All Apps %TXT_RED%(Risky)%RESET%
echo  %TXT_GRN%[M]%RESET%anual Review Every App %TXT_GRAY%(Recommended)%RESET%
echo  %TXT_GRN%[S]%RESET%kip Phase #1 %TXT_GRAY%(Proceed to Phase #2)%RESET%
echo.
echo  Press %TXT_GRN%[A]%RESET%, %TXT_GRN%[M]%RESET% or %TXT_GRN%[S]%RESET%...

choice /c AMS /n >nul
set "PHASE1_CHOICE=%errorlevel%"

if "%PHASE1_CHOICE%"=="3" goto PHASE2_INIT

if "%PHASE1_CHOICE%"=="2" (
    cls
    echo.
    echo  %BG_GRN%  MANUAL MODE ENGAGED                                                                                               %RESET%
    echo.
    echo  %TXT_GRAY%Press any key to start...%RESET%
    pause >nul
)

for %%p in (%apps_p1%) do (
    call :GET_APP_NAME %%p
    if "%PHASE1_CHOICE%"=="1" (
        call :EXECUTE_ACTION %%p "!APP_LABEL!" "SAFE"
    ) else (
        call :ASK_USER %%p "!APP_LABEL!" "SAFE"
    )
)

:: ===============================================================================================
::  PHASE 2: ADVANCED APPS
:: ===============================================================================================
:PHASE2_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 2/4 %TXT_YEL%^|%TXT_WHT% User Tools ^& Features%RESET%
echo  %TXT_GRAY%  Phase 2 of 4 in total%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BG_YEL%  SELECT MODE                                                                                                       %RESET%
echo.
echo  These apps are visible on your home screen (Gallery, Weather, File Manager, etc).
echo  Only remove them if you have a replacement app installed.
echo.
echo  %TXT_YEL%[A]%RESET%uto Process All Apps %TXT_RED%(Risky)%RESET%
echo  %TXT_YEL%[M]%RESET%anual Review Every App %TXT_GRN%(Recommended)%RESET%
echo  %TXT_YEL%[S]%RESET%kip Phase #2 %TXT_GRAY%(Proceed to Phase #3)%RESET%
echo.
echo  Press %TXT_YEL%[A]%RESET%, %TXT_YEL%[M]%RESET% or %TXT_YEL%[S]%RESET%...

choice /c AMS /n >nul
set "PHASE2_CHOICE=%errorlevel%"

if "%PHASE2_CHOICE%"=="3" goto PHASE3_INIT

if "%PHASE2_CHOICE%"=="2" (
    cls
    echo.
    echo  %BG_YEL%  MANUAL MODE ENGAGED                                                                                               %RESET%
    echo.
    echo  %TXT_GRAY%Press any key to start...%RESET%
    pause >nul
)

for %%p in (%apps_p2%) do (
    call :GET_APP_NAME %%p
    if "%PHASE2_CHOICE%"=="1" (
        call :EXECUTE_ACTION %%p "!APP_LABEL!" "CAUTION"
    ) else (
        call :ASK_USER %%p "!APP_LABEL!" "CAUTION"
    )
)

:: ===============================================================================================
::  PHASE 3: RISKY SYSTEM APPS
:: ===============================================================================================
:PHASE3_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 3/4 %TXT_RED%^|%TXT_WHT% Risky System Apps%RESET%
echo  %TXT_GRAY%  Phase 3 of 4 in total%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BG_RED%  SELECT MODE                                                                                                       %RESET%
echo.
echo  Contains HyperOS core apps (App Vault, Security, GetApps, Themes).
echo  Removing some of these may cause bootloops on certain firmware versions!
echo.
echo  %TXT_RED%[A]%RESET%uto Process All Apps %TXT_RED%(Risky)%RESET%
echo  %TXT_RED%[M]%RESET%anual Review Every App %TXT_GRN%(Recommended)%RESET%
echo  %TXT_RED%[S]%RESET%kip Phase #3 %TXT_GRAY%(Proceed to Phase #4)%RESET%
echo.
echo  Press %TXT_RED%[A]%RESET%, %TXT_RED%[M]%RESET% or %TXT_RED%[S]%RESET%...

choice /c AMS /n >nul
set "PHASE3_CHOICE=%errorlevel%"

if "%PHASE3_CHOICE%"=="3" goto PHASE4_INIT

if "%PHASE3_CHOICE%"=="2" (
    cls
    echo.
    echo  %BG_RED%  MANUAL MODE ENGAGED                                                                                               %RESET%
    echo.
    echo  %TXT_GRAY%Press any key to start...%RESET%
    pause >nul
)

for %%p in (%apps_p3%) do (
    call :GET_APP_NAME %%p
    if "%PHASE3_CHOICE%"=="1" (
        call :EXECUTE_ACTION %%p "!APP_LABEL!" "DANGER"
    ) else (
        call :ASK_USER %%p "!APP_LABEL!" "DANGER"
    )
)

:: ===============================================================================================
::  PHASE 4: HIDDEN SYSTEM APPS
:: ===============================================================================================
:PHASE4_INIT
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  PHASE 4/4 %TXT_MAG%^|%TXT_WHT% Hidden System Apps (Canta Suggestions)%RESET%
echo  %TXT_GRAY%  Phase 4 of 4 in total%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BG_MAG%  SELECT MODE                                                                                                       %RESET%
echo.
echo  These are hidden APIs, Android core bloat, and Xiaomi telemetry.
echo  Usually safe, but might break specific deep-system functions.
echo.
echo  %TXT_MAG%[A]%RESET%uto Process All Apps %TXT_RED%(Risky)%RESET%
echo  %TXT_MAG%[M]%RESET%anual Review Every App %TXT_GRN%(Recommended)%RESET%
echo  %TXT_MAG%[S]%RESET%kip Phase #4 %TXT_GRAY%(Proceed to Finish)%RESET%
echo.
echo  Press %TXT_MAG%[A]%RESET%, %TXT_MAG%[M]%RESET% or %TXT_MAG%[S]%RESET%...

choice /c AMS /n >nul
set "PHASE4_CHOICE=%errorlevel%"

if "%PHASE4_CHOICE%"=="3" goto FINISH

if "%PHASE4_CHOICE%"=="2" (
    cls
    echo.
    echo  %BG_MAG%  MANUAL MODE ENGAGED                                                                                               %RESET%
    echo.
    echo  %TXT_GRAY%Press any key to start...%RESET%
    pause >nul
)

for %%p in (%apps_p4%) do (
    call :GET_APP_NAME %%p
    if "%PHASE4_CHOICE%"=="1" (
        call :EXECUTE_ACTION %%p "!APP_LABEL!" "HIDDEN"
    ) else (
        call :ASK_USER %%p "!APP_LABEL!" "HIDDEN"
    )
)

:: ===============================================================================================
::  FINISH
:: ===============================================================================================
:FINISH
cls
echo.
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  %BOLD%%TXT_WHT%  SUMMARY %TXT_CYAN%-%TXT_WHT% Complete%RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
echo  %BG_CYAN%  TASK COMPLETED                                                                                                    %RESET%
echo.
echo  %TXT_GRN%  [v]%RESET% Log saved to: %TXT_WHT%%LOGFILE%%RESET%
echo.
echo  %TXT_GRAY%  To restore an app manually via ADB use:%RESET%
echo  %TXT_GRAY%  adb shell cmd package install-existing ^<package_name^>%RESET%
echo.
echo  Press any key to return to Main Menu...
pause >nul
goto MAIN_MENU

:: ===============================================================================================
::  SUBROUTINES
:: ===============================================================================================

:PRINT_MANUAL_HEADER
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo  !THEME_BG!  XIAOMI HYPEROS DEBLOATER ^| App Processing                                                                      %RESET%
echo  %TXT_GRAY%====================================================================================================================%RESET%
echo.
goto :eof

:CHECK_APP_STATE
set "CHK_PKG=%~1"
set "APP_STATE=Not Installed / Removed"
set "APP_STATE_COLOR=%TXT_GRAY%"

!ADB_CMD! -s !TARGET_ID! shell pm list packages -u !CHK_PKG! > "%temp%\adb_chk.txt" 2>nul
findstr /I /E /C:"package:!CHK_PKG!" "%temp%\adb_chk.txt" >nul 2>&1
if !errorlevel! equ 0 (
    set "APP_STATE=Uninstalled (User 0)"
    set "APP_STATE_COLOR=%TXT_YEL%"

    !ADB_CMD! -s !TARGET_ID! shell pm list packages !CHK_PKG! > "%temp%\adb_chk.txt" 2>nul
    findstr /I /E /C:"package:!CHK_PKG!" "%temp%\adb_chk.txt" >nul 2>&1
    if !errorlevel! equ 0 (
        set "APP_STATE=Installed (Active)"
        set "APP_STATE_COLOR=%TXT_GRN%"
    )

    !ADB_CMD! -s !TARGET_ID! shell pm list packages -d !CHK_PKG! > "%temp%\adb_chk.txt" 2>nul
    findstr /I /E /C:"package:!CHK_PKG!" "%temp%\adb_chk.txt" >nul 2>&1
    if !errorlevel! equ 0 (
        set "APP_STATE=Frozen (Disabled)"
        set "APP_STATE_COLOR=%TXT_CYAN%"
    )
)
if exist "%temp%\adb_chk.txt" del "%temp%\adb_chk.txt" >nul 2>&1
goto :eof

:EXECUTE_ACTION
set "pkg=%~1"
set "lbl=%~2"
set "type=%~3"
if "%type%"=="SAFE" (set "THEME_BG=%BG_GRN%")
if "%type%"=="CAUTION" (set "THEME_BG=%BG_YEL%")
if "%type%"=="DANGER" (set "THEME_BG=%BG_RED%")
if "%type%"=="HIDDEN" (set "THEME_BG=%BG_MAG%")

if "%DO_LIVE_CHECK%"=="1" (
    call :CHECK_APP_STATE %pkg%

    if "!SKIP_NOT_INSTALLED!"=="1" (
        set "SHOULD_SKIP=0"
        set "SKIP_REASON="

        :: Smart Filter: Context-Aware Logic
        if "!MODE_NAME!"=="RESTORE" (
            if "!APP_STATE!"=="Installed (Active)" (
                set "SHOULD_SKIP=1"
                set "SKIP_REASON=App is already Installed and Active"
            )
        ) else (
            if "!APP_STATE!"=="Not Installed / Removed" (
                set "SHOULD_SKIP=1"
                set "SKIP_REASON=Not Installed"
            ) else if "!APP_STATE!"=="Uninstalled (User 0)" (
                if "!MODE_NAME!"=="UNINSTALL" (
                    set "SHOULD_SKIP=1"
                    set "SKIP_REASON=Already Uninstalled"
                )
            ) else if "!APP_STATE!"=="Frozen (Disabled)" (
                if "!MODE_NAME!"=="FREEZE" (
                    set "SHOULD_SKIP=1"
                    set "SKIP_REASON=Already Frozen"
                )
            )
        )

        if "!SHOULD_SKIP!"=="1" (
            echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
            echo  Processing: %TXT_WHT%!lbl!%RESET% ^(!pkg!^)
            echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%
            echo  %TXT_YEL%[!] Skipped automatically ^(!SKIP_REASON!^).%RESET%
            echo.
            timeout /t 1 >nul
            goto :eof
        )
    )
) else (
    set "APP_STATE=Unknown (Live Check Disabled)"
    set "APP_STATE_COLOR=%TXT_GRAY%"
)

echo  %TXT_GRAY%--------------------------------------------------------------------------------------------------------------------%RESET%
echo  Processing: %TXT_WHT%!lbl!%RESET% ^(!pkg!^)
echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%

if "!MODE_NAME!"=="RESTORE" (
    echo  Executing Action: RESTORE...
    !ADB_CMD! -s !TARGET_ID! shell cmd package install-existing %pkg% >nul 2>&1
    !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1
) else (
    echo  Executing Action: %CMD_ACTION%...
    !ADB_CMD! -s !TARGET_ID! shell %CMD_ACTION% %pkg% >nul 2>&1
)

echo  %TXT_GRN%[OK] Command Sent.%RESET%

echo  %time% ^| %MODE_VERB% ^| %pkg% ^| !lbl! >> "%LOGFILE%"
echo.
timeout /t 1 >nul
goto :eof

:ASK_USER
set "pkg=%~1"
set "lbl=%~2"
set "type=%~3"
if "%type%"=="SAFE" (set "THEME_BG=%BG_GRN%")
if "%type%"=="CAUTION" (set "THEME_BG=%BG_YEL%")
if "%type%"=="DANGER" (set "THEME_BG=%BG_RED%")
if "%type%"=="HIDDEN" (set "THEME_BG=%BG_MAG%")

if "%DO_LIVE_CHECK%"=="1" (
    cls
    call :PRINT_MANUAL_HEADER
    echo  %TXT_GRAY%Reading info about app: %TXT_WHT%!lbl!%TXT_GRAY% ^(!pkg!^)...%RESET%
    call :CHECK_APP_STATE %pkg%

    if "!SKIP_NOT_INSTALLED!"=="1" (
        set "SHOULD_SKIP=0"
        set "SKIP_REASON="

        if "!MODE_NAME!"=="RESTORE" (
            if "!APP_STATE!"=="Installed (Active)" (
                set "SHOULD_SKIP=1"
                set "SKIP_REASON=App is already Installed and Active"
            )
        ) else (
            if "!APP_STATE!"=="Not Installed / Removed" (
                set "SHOULD_SKIP=1"
                set "SKIP_REASON=Not Installed"
            ) else if "!APP_STATE!"=="Uninstalled (User 0)" (
                if "!MODE_NAME!"=="UNINSTALL" (
                    set "SHOULD_SKIP=1"
                    set "SKIP_REASON=Already Uninstalled"
                )
            ) else if "!APP_STATE!"=="Frozen (Disabled)" (
                if "!MODE_NAME!"=="FREEZE" (
                    set "SHOULD_SKIP=1"
                    set "SKIP_REASON=Already Frozen"
                )
            )
        )

        if "!SHOULD_SKIP!"=="1" (
            echo.
            echo  %TXT_YEL%[!] Skipped automatically ^(!SKIP_REASON!^).%RESET%
            timeout /t 1 >nul
            goto :eof
        )
    )
) else (
    set "APP_STATE=Unknown ^(Live Check Disabled^)"
    set "APP_STATE_COLOR=%TXT_GRAY%"
)

:: Setup Dynamic Controls based on current mode
set "CHOICES=YNE"
set "PROMPT_TEXT=>> %MODE_NAME%?  %TXT_GRN%[Y]%RESET%es - %MODE_VERB%   %TXT_RED%[N]%RESET%o - Skip   %TXT_CYAN%[E]%RESET%xit Debloater"

if "!APP_STATE!"=="Frozen (Disabled)" (
    set "CHOICES=YNEU"
    set "PROMPT_TEXT=>> %MODE_NAME%?  %TXT_GRN%[Y]%RESET%es - %MODE_VERB%   %TXT_RED%[N]%RESET%o - Skip   %TXT_YEL%[U]%RESET%nfreeze   %TXT_CYAN%[E]%RESET%xit Debloater"
)

:: Re-render screen with real data
cls
call :PRINT_MANUAL_HEADER
echo  %BOLD%!lbl!%RESET%
echo  %TXT_GRAY%%pkg%%RESET%
echo  App Status: !APP_STATE_COLOR!!APP_STATE!%RESET%
echo.
echo  !PROMPT_TEXT!

choice /c !CHOICES! /n >nul
if errorlevel 4 (
    echo.
    echo  Processing: Unfreezing !lbl!...
    !ADB_CMD! -s !TARGET_ID! shell pm enable %pkg% >nul 2>&1
    echo  %time% ^| UNFREEZE ^| %pkg% ^| !lbl! >> "%LOGFILE%"
    timeout /t 1 >nul
    goto :eof
)
if errorlevel 3 goto FINISH
if errorlevel 2 (
    echo  %TXT_RED% [--] Skipped.%RESET%
    echo  %time% ^| SKIPPED ^| %pkg% ^| !lbl! >> "%LOGFILE%"
    timeout /t 1 >nul
) else (
    call :EXECUTE_ACTION %pkg% "!lbl!" "MANUAL_CALL"
)
goto :eof

:GET_APP_NAME
set "pkg=%~1"
set "APP_LABEL=%~1"

:: --- PHASE 1: SAFE ---
if "%pkg%"=="com.miui.analytics" set "APP_LABEL=MIUI Analytics (Ad Tracking)"
if "%pkg%"=="com.miui.msa.global" set "APP_LABEL=MSA (Main System Ads Service)"
if "%pkg%"=="com.miui.daemon" set "APP_LABEL=MIUI Daemon (Data Collection)"
if "%pkg%"=="com.xiaomi.joyose" set "APP_LABEL=Joyose (Performance Throttling/Junk)"
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

:: --- PHASE 2: ADVANCED ---
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

:: --- PHASE 3: RISKY ---
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

:: --- PHASE 4: HIDDEN (CANTA) ---
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