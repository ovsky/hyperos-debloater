#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$SCRIPT_DIR

. "$ROOT_DIR/data/code/hyperos_common.sh"

ensure_config

load_advanced_values() {
    V_SMART=$(config_bool "smartFiltering")
    V_PREVIEW=$(config_bool "showPreview")
    V_LOG=$(config_bool "logToText")
    V_DIS=$(config_bool "disableInsteadOfUninstall")
    V_REBOOT=$(config_bool "rebootAfterRestore")
    V_CORE=$(config_bool "skipSystemCore")
    V_ADB=$(config_bool "forceADBRestart")
    V_SIM=$(config_bool "simulationMode")
}

save_advanced_values() {
    config_set_bool "smartFiltering" "$V_SMART"
    config_set_bool "showPreview" "$V_PREVIEW"
    config_set_bool "logToText" "$V_LOG"
    config_set_bool "disableInsteadOfUninstall" "$V_DIS"
    config_set_bool "rebootAfterRestore" "$V_REBOOT"
    config_set_bool "skipSystemCore" "$V_CORE"
    config_set_bool "forceADBRestart" "$V_ADB"
    config_set_bool "simulationMode" "$V_SIM"
}

restore_defaults_silent() {
    cp "$CONFIG_DEFAULT_PATH" "$CONFIG_PATH"
}

manage_joyose_policy() {
    clear_screen
    printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
    printf '%s  JOYOSE POLICY CONFIGURATION%s\n' "$BOLD$TXT_WHT" "$RESET"
    printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"
    printf '%sWARNING:%s\n' "$TXT_YEL" "$RESET"
    printf '%sJoyose is a thermal/performance service. Disabling it can improve performance on some devices, but it can also cause thermal throttling or unexpected behavior.%s\n\n' "$TXT_GRAY" "$RESET"
    printf 'How should the Debloater handle Joyose?\n'
    printf '[A] Ask me every time (Recommended)\n'
    printf '[R] Automatically remove it always (Expert)\n'
    printf '[K] Keep it installed and do not touch it (Safest)\n\n'
    printf '[E] Exit without saving\n\n'

    mj_choice=$(read_choice "ARKE" "Choice: ")
    case "$mj_choice" in
        A) config_set_string "joyoseAction" "ASK" ;;
        R) config_set_string "joyoseAction" "REMOVE" ;;
        K) config_set_string "joyoseAction" "KEEP" ;;
        E) return ;;
    esac

    printf '\n%s[v] JSON Configuration updated.%s\n' "$TXT_GRN" "$RESET"
    sleep 2
}

advanced_config() {
    load_advanced_values
    CHANGES_MADE=0

    while :; do
        D_SMART=$(status_label "$V_SMART")
        D_PREVIEW=$(status_label "$V_PREVIEW")
        D_LOG=$(status_label "$V_LOG")
        D_DIS=$(status_label "$V_DIS")
        D_REBOOT=$(status_label "$V_REBOOT")
        D_CORE=$(status_label "$V_CORE")
        D_ADB=$(status_label "$V_ADB")
        D_SIM=$(status_label "$V_SIM")

        clear_screen
        printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        printf '%s  ADVANCED SETTINGS CONFIGURATION%s\n' "$BOLD$TXT_WHT" "$RESET"
        printf '%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        [ "$CHANGES_MADE" = "1" ] && printf '%s  [!] You have unsaved modifications. Press [S] to save them.%s\n' "$BG_YEL" "$RESET"
        printf '\n'
        printf '[1] Smart Filtering             [%s] %s(Auto-skips apps already in target state)%s\n' "$D_SMART" "$TXT_GRAY" "$RESET"
        printf '[2] Show Previews               [%s] %s(Displays lists before running phases)%s\n' "$D_PREVIEW" "$TXT_GRAY" "$RESET"
        printf '[3] Log to Text File            [%s] %s(Saves debloat logs to /logs folder)%s\n' "$D_LOG" "$TXT_GRAY" "$RESET"
        printf '[4] Freeze instead of Uninstall [%s] %s(Uses pm disable-user instead of uninstall -k)%s\n' "$D_DIS" "$TXT_GRAY" "$RESET"
        printf '[5] Auto-Reboot after Restore   [%s] %s(Reboots device automatically when Restorer finishes)%s\n' "$D_REBOOT" "$TXT_GRAY" "$RESET"
        printf '[6] Protect Core System Apps    [%s] %s(Automatically skips Phase 3 Risky Apps)%s\n' "$D_CORE" "$TXT_GRAY" "$RESET"
        printf '[7] Force ADB Restart on Boot   [%s] %s(Kills and restarts ADB server upon script launch)%s\n' "$D_ADB" "$TXT_GRAY" "$RESET"
        printf '\n%s--- [DEBUG / DEVELOPMENT] ------------------------------------------------------------------------------------------%s\n' "$TXT_GRAY" "$RESET"
        printf '[8] [DEBUG] Simulation Mode     [%s] %s(Prints ADB commands without running them)%s\n' "$D_SIM" "$TXT_GRAY" "$RESET"
        printf '\n%s--- [SETTINGS] -----------------------------------------------------------------------------------------------------%s\n' "$TXT_GRAY" "$RESET"
        printf '[S] Save Modified Settings\n'
        printf '[D] Restore Default Settings\n'
        printf '\n%s--- [MENU] ---------------------------------------------------------------------------------------------------------%s\n' "$TXT_GRAY" "$RESET"
        printf '[E] Exit to Main Menu\n\n'

        ac_choice=$(read_choice "12345678SDE" "Choice: ")
        case "$ac_choice" in
            1) V_SMART=$(bool_toggle "$V_SMART"); CHANGES_MADE=1 ;;
            2) V_PREVIEW=$(bool_toggle "$V_PREVIEW"); CHANGES_MADE=1 ;;
            3) V_LOG=$(bool_toggle "$V_LOG"); CHANGES_MADE=1 ;;
            4) V_DIS=$(bool_toggle "$V_DIS"); CHANGES_MADE=1 ;;
            5) V_REBOOT=$(bool_toggle "$V_REBOOT"); CHANGES_MADE=1 ;;
            6) V_CORE=$(bool_toggle "$V_CORE"); CHANGES_MADE=1 ;;
            7) V_ADB=$(bool_toggle "$V_ADB"); CHANGES_MADE=1 ;;
            8) V_SIM=$(bool_toggle "$V_SIM"); CHANGES_MADE=1 ;;
            S)
                save_advanced_values
                CHANGES_MADE=0
                printf '\n%s[v] Settings saved successfully.%s\n' "$TXT_GRN" "$RESET"
                sleep 2
                ;;
            D)
                printf '\n%sWARNING: Are you sure you want to restore all Advanced Settings to their defaults?%s\n' "$TXT_YEL" "$RESET"
                rd_choice=$(read_choice "YN" "[Y]es, restore   [N]o, cancel: ")
                if [ "$rd_choice" = "Y" ]; then
                    restore_defaults_silent
                    load_advanced_values
                    CHANGES_MADE=0
                    printf '\n%s[v] Default settings restored successfully.%s\n' "$TXT_GRN" "$RESET"
                    sleep 2
                fi
                ;;
            E)
                if [ "$CHANGES_MADE" = "1" ]; then
                    printf '\n%s[!] You have unsaved changes.%s\n' "$TXT_YEL" "$RESET"
                    exit_choice=$(read_choice "YNC" "[Y]es, save   [N]o, discard   [C]ancel exit: ")
                    case "$exit_choice" in
                        C) ;;
                        N) return ;;
                        Y)
                            save_advanced_values
                            return
                            ;;
                    esac
                else
                    return
                fi
                ;;
        esac
    done
}

main_menu() {
    while :; do
        JOYOSE_ACTION=$(config_get "joyoseAction")
        [ -n "$JOYOSE_ACTION" ] || JOYOSE_ACTION="ASK"

        clear_screen
        printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        printf '%s  HYPEROS DEBLOAT MANAGER %s-%s Master Dashboard%s\n' "$BOLD$TXT_WHT" "$TXT_CYAN" "$TXT_WHT" "$RESET"
        printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"
        printf '%s[1]%s Start Debloater %s(data/code/debloat_hyperos.sh)%s\n' "$TXT_CYAN" "$RESET" "$TXT_GRAY" "$RESET"
        printf '%sLaunch the interactive tool to safely remove or freeze bloatware.%s\n\n' "$TXT_GRAY" "$RESET"
        printf '%s[2]%s Start Full Restorer %s(data/code/debloat_restore.sh)%s\n' "$TXT_GRN" "$RESET" "$TXT_GRAY" "$RESET"
        printf '%sRecover all standard, advanced, risky, and hidden apps from the config database.%s\n\n' "$TXT_GRAY" "$RESET"
        printf '%s[3]%s Manage Joyose Policy %s(Current Setting: %s)%s\n' "$TXT_YEL" "$RESET" "$TXT_GRAY" "$JOYOSE_ACTION" "$RESET"
        printf '%sConfigure how the script handles com.xiaomi.joyose (Thermal Management).%s\n\n' "$TXT_GRAY" "$RESET"
        printf '%s[4]%s Advanced Config Settings\n' "$TXT_MAG" "$RESET"
        printf '%sToggle smart filtering, simulation mode, uninstallation methods, and more.%s\n\n' "$TXT_GRAY" "$RESET"
        printf '%s[E]%s Exit\n\n' "$TXT_RED" "$RESET"

        mm_choice=$(read_choice "1234E" "Choice: ")
        case "$mm_choice" in
            1) sh "$ROOT_DIR/data/code/debloat_hyperos.sh" ;;
            2) sh "$ROOT_DIR/data/code/debloat_restore.sh" ;;
            3) manage_joyose_policy ;;
            4) advanced_config ;;
            E) exit 0 ;;
        esac
    done
}

main_menu
