#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

. "$SCRIPT_DIR/hyperos_common.sh"

ensure_config
load_runtime_settings
prepare_runtime || exit 1
require_adb

create_restore_list() {
    {
        cat "$RUNTIME_DIR/phase1_safe"
        cat "$RUNTIME_DIR/phase2_advanced"
        cat "$RUNTIME_DIR/phase3_risky"
        cat "$RUNTIME_DIR/phase4_hidden"
        cat "$RUNTIME_DIR/restore_only"
        printf '%s\n' "com.xiaomi.joyose"
    } | awk 'NF && !seen[$0]++' > "$RUNTIME_DIR/all_restore_packages"
}

wait_for_device() {
    if [ "$SIM_MODE" = "1" ] && ! command -v "$ADB_CMD" >/dev/null 2>&1 && [ ! -x "$ADB_CMD" ]; then
        TARGET_ID="SIMULATED"
        TARGET_MODEL="Simulation Mode"
        return
    fi

    while :; do
        clear_screen
        printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        printf '%s  HYPEROS ESSENTIAL APP RESTORER%s\n' "$BG_GRN" "$RESET"
        printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"
        [ "$SIM_MODE" = "1" ] && printf '%s  [DEBUG SIMULATION MODE ACTIVE] Commands will not be executed.%s\n\n' "$TXT_MAG" "$RESET"
        printf '%s  STATUS: WAITING FOR DEVICE...%s\n' "$BG_CYAN" "$RESET"
        printf '%sAuto-scanning for connected devices...\nEnsure USB Debugging is ON. Press Ctrl+C to cancel.%s\n\n' "$TXT_GRAY" "$RESET"

        TARGET_ID=$(adb_run devices -l 2>/dev/null | awk 'NR > 1 && $2 == "device" { print $1; exit }')
        if [ -n "$TARGET_ID" ]; then
            TARGET_MODEL=$(adb_run -s "$TARGET_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r' | sed -n '1p')
            [ -n "$TARGET_MODEL" ] || TARGET_MODEL="Unknown Device"
            printf '%s  [v]%s Connected Model: %s%s%s\n' "$TXT_GRN" "$RESET" "$TXT_WHT" "$TARGET_MODEL" "$RESET"
            sleep 2
            return
        fi
        sleep 2
    done
}

restore_sequence() {
    clear_screen
    printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
    printf '%s  HYPEROS ESSENTIAL APP RESTORER%s\n' "$BG_GRN" "$RESET"
    printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"
    printf '%s[+] Device Connected. Beginning Full Restoration Sequence...%s\n\n' "$TXT_GRN" "$RESET"

    while IFS= read -r restore_pkg; do
        [ -n "$restore_pkg" ] || continue
        printf '  %sAttempting to restore:%s %s%s%s\n' "$TXT_GRAY" "$RESET" "$TXT_WHT" "$restore_pkg" "$RESET"
        if [ "$SIM_MODE" = "1" ]; then
            printf '  %s[DEBUG]%s %s -s %s shell cmd package install-existing --user 0 %s\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID" "$restore_pkg"
            printf '  %s[DEBUG]%s %s -s %s shell pm enable --user 0 %s\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID" "$restore_pkg"
        else
            adb_run -s "$TARGET_ID" shell cmd package install-existing --user 0 "$restore_pkg" >/dev/null 2>&1
            adb_run -s "$TARGET_ID" shell pm enable --user 0 "$restore_pkg" >/dev/null 2>&1
        fi
    done < "$RUNTIME_DIR/all_restore_packages"

    printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
    printf '%s  RESTORATION COMPLETE%s\n' "$BG_GRN" "$RESET"
    printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"

    if [ "$REBOOT_RESTORE" = "1" ]; then
        printf '%sAuto-Reboot is enabled. Rebooting device...%s\n' "$TXT_CYAN" "$RESET"
        if [ "$SIM_MODE" = "1" ]; then
            printf '  %s[DEBUG]%s %s -s %s reboot\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID"
        else
            adb_run -s "$TARGET_ID" reboot
        fi
    else
        printf '%sPlease restart your device manually to ensure all system apps reinitialize properly.%s\n' "$TXT_WHT" "$RESET"
    fi

    pause_screen
}

create_restore_list

if [ "$SIM_MODE" != "1" ] || command -v "$ADB_CMD" >/dev/null 2>&1 || [ -x "$ADB_CMD" ]; then
    adb_run start-server >/dev/null 2>&1 || true
fi

wait_for_device
restore_sequence
