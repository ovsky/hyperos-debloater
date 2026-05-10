@echo off
:: ===============================================================================================
::  SHARED CONFIGURATION & APP DEFINITIONS
:: ===============================================================================================

:: Joyose handling: ASK, REMOVE, or KEEP
set "JOYOSE_ACTION=ASK"

:: 1. PHASE 1: SAFE LIST (Joyose removed from hardcoded list, managed dynamically)
set "apps_p1=com.miui.analytics com.miui.systemAdSolution com.miui.msa.global com.miui.daemon com.facebook.appmanager com.facebook.services com.facebook.system com.facebook.katana com.miui.cleanmaster com.miui.miservice com.miui.touchassistant com.miui.hybrid com.miui.hybrid.accessory com.xiaomi.discover com.xiaomi.ab com.miui.cit com.miui.wmsvc com.miui.userguide com.miui.backup com.xiaomi.xmsf com.mi.global.bbs com.mi.global.shop com.miui.nextpay com.miui.tsmclient com.miui.greenguard com.xiaomi.gamecenter com.xiaomi.gamecenter.sdk.service com.miui.uireporter com.miui.securityadd com.baidu.input_mi com.iflytek.inputmethod.miui com.sohu.inputmethod.sogou.xiaomi com.tencent.soter.soterserver com.bsp.catchlog com.xiaomi.security.onetrack com.wapi.wapicertmanage com.miui.newmidrive com.xiaomi.aireco com.qti.qualcomm.deviceinfo com.unionpay.tsmservice.mi com.miui.guardprovider com.miui.powerinsight com.miui.yellowpage com.xiaomi.pass com.mipay.wallet"

:: 2. PHASE 2: ADVANCED LIST (User-Facing Apps)
set "apps_p2=com.miui.compass com.miui.weather2 com.miui.notes com.miui.calculator com.miui.videoplayer com.miui.player com.xiaomi.glgm com.miui.gallery com.xiaomi.midrop com.miui.fmservice com.miui.fm com.android.stk com.xiaomi.payment com.xiaomi.vipaccount com.duokan.phone.remotecontroller com.xiaomi.smarthome com.android.calendar com.miui.calendar com.android.deskclock com.android.providers.downloads.ui com.android.fileexplorer com.mi.android.globalFileexplorer com.android.soundrecorder com.android.email com.miui.screenrecorder com.miui.huanji com.android.browser com.miui.browser cn.wps.moffice_eng.xiaomi.lite com.miui.qr com.miui.mediaviewer com.miui.mediaeditor"

:: 3. PHASE 3: RISKY SYSTEM APPS 
set "apps_p3=com.miui.personalassistant com.miui.appvault com.miui.themestore com.android.thememanager com.xiaomi.thememanager com.miui.findmy com.xiaomi.finddevice com.xiaomi.scanner com.miui.scanner com.xiaomi.market com.xiaomi.mipicks com.miui.securitycenter com.xiaomi.account com.miui.cloudservice com.miui.micloudsync com.miui.cloudbackup com.xiaomi.roaming com.miui.roaming"

:: 4. PHASE 4: HIDDEN SYSTEM APPS
set "apps_p4=com.miui.aod com.xiaomi.hypercomm com.miui.audiomonitor com.miui.voiceassistProxy com.xiaomi.aiasst.service com.xiaomi.aiasst.vision com.xiaomi.mibrain.speech com.xiaomi.metoknlp com.android.dreams.basic com.android.dreams.phototable com.android.printspooler com.android.bips com.android.bookmarkprovider com.android.traceur com.miui.contentextension com.miui.carlink com.miui.thirdappassistant com.xiaomi.aicr com.miui.misightservice com.xiaomi.barrage com.xiaomi.mirror com.miui.voiceassistoverlay"

:: 5. RESTORE ONLY LIST (Includes extra essential modules)
set "apps_restore_only=com.miui.extraphoto com.miui.face com.android.egg com.miui.freeform com.miui.mishare.connectivity com.miui.phrase com.miui.vsimcore com.miui.virtualsim com.lbe.security.miui com.miui.permission com.android.providers.media.module com.android.providers.media com.android.settings"