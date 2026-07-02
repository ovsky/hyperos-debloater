#!/bin/sh

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

. "$SCRIPT_DIR/hyperos_common.sh"

ensure_config
load_runtime_settings
prepare_runtime || exit 1
require_adb
start_log

create_all_package_list() {
    {
        cat "$RUNTIME_DIR/phase1_safe"
        cat "$RUNTIME_DIR/phase2_advanced"
        cat "$RUNTIME_DIR/phase3_risky"
        cat "$RUNTIME_DIR/phase4_hidden"
        cat "$RUNTIME_DIR/restore_only"
        printf '%s\n' "com.xiaomi.joyose"
    } | awk 'NF && !seen[$0]++' > "$RUNTIME_DIR/all_packages"
}

create_all_package_list

cache_device_state() {
    if [ "$SIM_MODE" = "1" ] && [ "$TARGET_ID" = "SIMULATED" ]; then
        awk '{ print "package:" $0 }' "$RUNTIME_DIR/all_packages" > "$RUNTIME_DIR/adb_all.txt"
        awk '{ print "package:" $0 }' "$RUNTIME_DIR/all_packages" > "$RUNTIME_DIR/adb_active.txt"
        : > "$RUNTIME_DIR/adb_disabled.txt"
        CACHE_READY=1
        return
    fi

    CACHE_READY=0
    cache_adb_packages "-u" "$RUNTIME_DIR/adb_all.txt" "adb_all.txt" "0" || return 1
    cache_adb_packages "-e" "$RUNTIME_DIR/adb_active.txt" "adb_active.txt" "0" || return 1
    cache_adb_packages "-d" "$RUNTIME_DIR/adb_disabled.txt" "adb_disabled.txt" "1" || return 1
    CACHE_READY=1
}

cache_adb_packages() {
    cap_arg=$1
    cap_output=$2
    cap_name=$3
    cap_allow_empty=$4
    cap_tmp="$RUNTIME_DIR/$cap_name.tmp"

    if ! adb_run -s "$TARGET_ID" shell pm list packages "$cap_arg" > "$cap_tmp" 2>/dev/null; then
        report_error "ADB cache failed: adb_run pm list packages $cap_arg could not write $cap_output"
        log_action "CACHE_ERROR" "$cap_name"
        rm -f "$cap_tmp" "$cap_output"
        return 1
    fi
    if ! sed 's/\r$//' "$cap_tmp" > "$cap_output"; then
        report_error "ADB cache failed: could not normalize $cap_tmp into $cap_output"
        log_action "CACHE_ERROR" "$cap_name"
        rm -f "$cap_tmp" "$cap_output"
        return 1
    fi
    rm -f "$cap_tmp"

    if [ ! -s "$cap_output" ]; then
        if [ "$cap_allow_empty" = "1" ]; then
            printf '%s[!] ADB cache warning: %s is empty after adb_run.%s\n' "$TXT_YEL" "$cap_output" "$RESET" >&2
            log_action "CACHE_WARN" "$cap_name empty"
            return 0
        fi
        report_error "ADB cache failed: $cap_output is empty after adb_run"
        log_action "CACHE_ERROR" "$cap_name empty"
        rm -f "$cap_output"
        return 1
    fi
}

require_cache_ready() {
    if [ "${CACHE_READY:-0}" != "1" ]; then
        report_error "Device package cache is not ready; refresh the cache before continuing."
        return 1
    fi
}

wait_for_device() {
    if [ "$SIM_MODE" = "1" ] && ! command -v "$ADB_CMD" >/dev/null 2>&1 && [ ! -x "$ADB_CMD" ]; then
        TARGET_ID="SIMULATED"
        TARGET_MODEL="Simulation Mode"
        cache_device_state
        return
    fi

    while :; do
        clear_screen
        printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        printf '%s  HYPEROS DEBLOAT COMMANDER %s-%s System Ready%s\n' "$BOLD$TXT_WHT" "$TXT_CYAN" "$TXT_WHT" "$RESET"
        printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"
        [ "$SIM_MODE" = "1" ] && printf '%s  [DEBUG SIMULATION MODE ACTIVE] Commands will NOT be executed on the device.%s\n\n' "$BG_YEL" "$RESET"
        printf '%s  STATUS: WAITING FOR DEVICE...%s\n' "$BG_CYAN" "$RESET"
        printf '%sAuto-scanning for connected devices...\nEnsure USB Debugging is ON. Press Ctrl+C to cancel.%s\n\n' "$TXT_GRAY" "$RESET"

        TARGET_ID=$(adb_run devices -l 2>/dev/null | awk 'NR > 1 && $2 == "device" { print $1; exit }')
        if [ -n "$TARGET_ID" ]; then
            TARGET_MODEL=$(adb_run -s "$TARGET_ID" shell getprop ro.product.model 2>/dev/null | tr -d '\r' | sed -n '1p')
            [ -n "$TARGET_MODEL" ] || TARGET_MODEL="Unknown Device"
            printf '%s  [v]%s Connected Model: %s%s%s\n' "$TXT_GRN" "$RESET" "$TXT_WHT" "$TARGET_MODEL" "$RESET"
            sleep 2
            if cache_device_state; then
                return
            fi
            sleep 2
        fi
        sleep 2
    done
}

check_app_state() {
    chk_pkg=$1
    APP_STATE="Not Installed / Removed"
    APP_STATE_COLOR="$TXT_GRAY"
    require_cache_ready || return 1

    if grep -Fqx "package:$chk_pkg" "$RUNTIME_DIR/adb_all.txt" 2>/dev/null; then
        APP_STATE="Uninstalled (User 0)"
        APP_STATE_COLOR="$TXT_YEL"
        if grep -Fqx "package:$chk_pkg" "$RUNTIME_DIR/adb_active.txt" 2>/dev/null; then
            APP_STATE="Installed (Active)"
            APP_STATE_COLOR="$TXT_GRN"
        fi
        if grep -Fqx "package:$chk_pkg" "$RUNTIME_DIR/adb_disabled.txt" 2>/dev/null; then
            APP_STATE="Frozen (Disabled)"
            APP_STATE_COLOR="$TXT_CYAN"
        fi
    fi
}

should_skip_current_state() {
    [ "$SKIP_NOT_INSTALLED" = "1" ] || return 1

    case "$MODE_NAME" in
        RESTORE)
            [ "$APP_STATE" = "Installed (Active)" ] && return 0
            ;;
        SAFE_REMOVE|FREEZE)
            case "$APP_STATE" in
                "Not Installed / Removed"|"Uninstalled (User 0)"|"Frozen (Disabled)")
                    return 0
                    ;;
            esac
            ;;
    esac

    return 1
}

restore_package() {
    rp_pkg=$1
    if [ "$SIM_MODE" = "1" ]; then
        printf '  %s[DEBUG]%s %s -s %s shell cmd package install-existing --user 0 %s\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID" "$rp_pkg"
        printf '  %s[DEBUG]%s %s -s %s shell pm enable --user 0 %s\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID" "$rp_pkg"
    else
        adb_run -s "$TARGET_ID" shell cmd package install-existing --user 0 "$rp_pkg" >/dev/null 2>&1
        adb_run -s "$TARGET_ID" shell pm enable --user 0 "$rp_pkg" >/dev/null 2>&1
    fi
    log_action "RESTORE" "$rp_pkg"
}

remove_or_freeze_package() {
    rfp_pkg=$1
    if [ "$DISABLE_MODE" = "1" ]; then
        if [ "$SIM_MODE" = "1" ]; then
            printf '  %s[DEBUG]%s %s -s %s shell pm disable-user --user 0 %s\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID" "$rfp_pkg"
        else
            adb_run -s "$TARGET_ID" shell pm disable-user --user 0 "$rfp_pkg" >/dev/null 2>&1
        fi
        log_action "FREEZE" "$rfp_pkg"
    else
        if [ "$SIM_MODE" = "1" ]; then
            printf '  %s[DEBUG]%s %s -s %s shell pm uninstall -k --user 0 %s\n' "$TXT_MAG" "$RESET" "$ADB_CMD" "$TARGET_ID" "$rfp_pkg"
        else
            adb_run -s "$TARGET_ID" shell pm uninstall -k --user 0 "$rfp_pkg" >/dev/null 2>&1
        fi
        log_action "UNINSTALL" "$rfp_pkg"
    fi
}

execute_action() {
    ea_pkg=$1
    ea_label=$2
    check_app_state "$ea_pkg" || return 1
    should_skip_current_state && return 0

    printf '  Processing: %s%s%s (%s)\n' "$TXT_WHT" "$ea_label" "$RESET" "$ea_pkg"
    if [ "$MODE_NAME" = "RESTORE" ]; then
        restore_package "$ea_pkg"
    else
        remove_or_freeze_package "$ea_pkg"
    fi
    [ "$SIM_MODE" = "1" ] && sleep 1
}

ask_user() {
    au_pkg=$1
    au_label=$2
    check_app_state "$au_pkg" || return 1
    should_skip_current_state && return 0

    while :; do
        clear_screen
        printf '%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        printf '%s%s%s (%s)\n' "$BOLD" "$au_label" "$RESET" "$au_pkg"
        printf 'App Status: %s%s%s\n\n' "$APP_STATE_COLOR" "$APP_STATE" "$RESET"

        if [ "$APP_STATE" = "Frozen (Disabled)" ]; then
            au_choice=$(read_choice "YNEU" ">> $MODE_VERB? [Y]es   [N]o   [U]nfreeze   [E]xit: ")
        else
            au_choice=$(read_choice "YNE" ">> $MODE_VERB? [Y]es   [N]o   [E]xit: ")
        fi

        case "$au_choice" in
            Y)
                execute_action "$au_pkg" "$au_label"
                return 0
                ;;
            N)
                return 0
                ;;
            U)
                restore_package "$au_pkg"
                cache_device_state || return 1
                return 0
                ;;
            E)
                return 2
                ;;
        esac
    done
}

process_phase() {
    pp_title=$1
    pp_color=$2
    pp_file=$3

    clear_screen
    printf '%s  %s%s\n' "$pp_color" "$pp_title" "$RESET"
    printf '[A]uto Process %s(Risky)%s   [M]anual Review %s(Recommended)%s   [S]kip Phase\n' "$TXT_RED" "$RESET" "$TXT_GRN" "$RESET"
    pp_choice=$(read_choice "AMS" "Choice: ")

    [ "$pp_choice" = "S" ] && return 0

    while IFS= read -r pp_pkg; do
        [ -n "$pp_pkg" ] || continue
        pp_label=$(app_label "$pp_pkg")
        if [ "$pp_choice" = "A" ]; then
            execute_action "$pp_pkg" "$pp_label"
            pp_result=$?
            [ "$pp_result" -ne 0 ] && return 1
        else
            ask_user "$pp_pkg" "$pp_label"
            pp_result=$?
            [ "$pp_result" -eq 2 ] && return 2
            [ "$pp_result" -ne 0 ] && return 1
        fi
    done < "$pp_file"

    return 0
}

build_explorer_list() {
    require_cache_ready || return 1
    bel_source=$RUNTIME_DIR/adb_all.txt
    [ "$SHOW_ACTIVE_ONLY" = "1" ] && bel_source=$RUNTIME_DIR/adb_active.txt

    : > "$RUNTIME_DIR/explorer_matches"
    while IFS= read -r bel_pkg; do
        [ -n "$bel_pkg" ] || continue
        if grep -Fqx "package:$bel_pkg" "$bel_source" 2>/dev/null; then
            bel_label=$(app_label "$bel_pkg")
            printf '%s\t%s\n' "$bel_label" "$bel_pkg" >> "$RUNTIME_DIR/explorer_matches"
        fi
    done < "$RUNTIME_DIR/all_packages"

    sort -f "$RUNTIME_DIR/explorer_matches" > "$RUNTIME_DIR/explorer_list"
    TOTAL_APPS=$(wc -l < "$RUNTIME_DIR/explorer_list" | tr -d ' ')
}

render_explorer() {
    re_window=25
    re_half=12
    re_start=$((CURRENT_INDEX - re_half))
    [ "$re_start" -lt 1 ] && re_start=1
    re_end=$((re_start + re_window - 1))
    if [ "$re_end" -gt "$TOTAL_APPS" ]; then
        re_end=$TOTAL_APPS
        re_start=$((re_end - re_window + 1))
        [ "$re_start" -lt 1 ] && re_start=1
    fi

    clear_screen
    printf '%s  INTERACTIVE APP EXPLORER | App %s of %s%s\n\n' "$BG_CYAN" "$CURRENT_INDEX" "$TOTAL_APPS" "$RESET"
    awk -F '\t' -v current="$CURRENT_INDEX" -v start="$re_start" -v end="$re_end" '
        NR >= start && NR <= end {
            marker = (NR == current) ? " > " : "   "
            printf "%s%s (%s)\n", marker, $1, $2
        }
    ' "$RUNTIME_DIR/explorer_list"
    printf '\n%s--------------------------------------------------------------------------------------------------------------------%s\n' "$TXT_GRAY" "$RESET"
    printf 'Controls: [W] Up  [S] Down  [A] Page Up  [D] Page Down  [E] Execute  [T] Toggle Filter  [B]ack\n'
}

selected_explorer_package() {
    awk -F '\t' -v current="$CURRENT_INDEX" 'NR == current { print $2; exit }' "$RUNTIME_DIR/explorer_list"
}

explorer_action_loop() {
    eal_pkg=$1
    eal_label=$(app_label "$eal_pkg")

    while :; do
        check_app_state "$eal_pkg" || return 1
        clear_screen
        printf '%sApp Name:%s    %s%s%s\n' "$BOLD" "$RESET" "$TXT_WHT" "$eal_label" "$RESET"
        printf '%sPackage ID:%s  %s%s%s\n' "$BOLD" "$RESET" "$TXT_WHT" "$eal_pkg" "$RESET"
        printf '%sApp Status:%s  %s%s%s\n\n' "$BOLD" "$RESET" "$APP_STATE_COLOR" "$APP_STATE" "$RESET"
        printf '[F] Remove / Freeze   [R] Unfreeze / Restore   [B]ack\n'
        eal_choice=$(read_choice "FRB" "Choice: ")

        case "$eal_choice" in
            F)
                remove_or_freeze_package "$eal_pkg"
                cache_device_state || return 1
                sleep 1
                ;;
            R)
                restore_package "$eal_pkg"
                cache_device_state || return 1
                sleep 1
                ;;
            B)
                return
                ;;
        esac
    done
}

interactive_explorer() {
    SHOW_ACTIVE_ONLY=0

    while :; do
        build_explorer_list || {
            pause_screen
            return
        }
        if [ "$TOTAL_APPS" -eq 0 ]; then
            printf '%s[!] No apps found for the current filter.%s\n' "$TXT_RED" "$RESET"
            pause_screen
            return
        fi

        CURRENT_INDEX=1
        while :; do
            render_explorer
            ie_choice=$(read_choice "WSADETB" "Choice: ")

            case "$ie_choice" in
                W)
                    [ "$CURRENT_INDEX" -gt 1 ] && CURRENT_INDEX=$((CURRENT_INDEX - 1))
                    ;;
                S)
                    [ "$CURRENT_INDEX" -lt "$TOTAL_APPS" ] && CURRENT_INDEX=$((CURRENT_INDEX + 1))
                    ;;
                A)
                    CURRENT_INDEX=$((CURRENT_INDEX - 10))
                    [ "$CURRENT_INDEX" -lt 1 ] && CURRENT_INDEX=1
                    ;;
                D)
                    CURRENT_INDEX=$((CURRENT_INDEX + 10))
                    [ "$CURRENT_INDEX" -gt "$TOTAL_APPS" ] && CURRENT_INDEX=$TOTAL_APPS
                    ;;
                E)
                    ie_pkg=$(selected_explorer_package)
                    [ -n "$ie_pkg" ] && explorer_action_loop "$ie_pkg"
                    build_explorer_list || {
                        pause_screen
                        return
                    }
                    [ "$TOTAL_APPS" -eq 0 ] && break
                    [ "$CURRENT_INDEX" -gt "$TOTAL_APPS" ] && CURRENT_INDEX=$TOTAL_APPS
                    ;;
                T)
                    if [ "$SHOW_ACTIVE_ONLY" = "1" ]; then
                        SHOW_ACTIVE_ONLY=0
                    else
                        SHOW_ACTIVE_ONLY=1
                    fi
                    break
                    ;;
                B)
                    return
                    ;;
            esac
        done
    done
}

mode_select() {
    require_cache_ready || {
        pause_screen
        return
    }

    clear_screen
    printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
    printf '%s  STEP 2: SELECT OPERATION MODE%s\n' "$BOLD$TXT_WHT" "$RESET"
    printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"

    if [ "$DISABLE_MODE" = "1" ]; then
        printf '[F]reeze Bloatware %s(Current Setting: pm disable-user)%s\n' "$TXT_GRAY" "$RESET"
        printf '[R]estore System Apps %s(Recovery Mode)%s\n\n' "$TXT_GRAY" "$RESET"
        ms_choice=$(read_choice "FR" "Choice: ")
    else
        printf '[S]afe Remove Bloatware %s(Current Setting: uninstall -k)%s\n' "$TXT_GRAY" "$RESET"
        printf '[R]estore System Apps %s(Recovery Mode)%s\n\n' "$TXT_GRAY" "$RESET"
        ms_choice=$(read_choice "SR" "Choice: ")
    fi

    cp "$RUNTIME_DIR/phase1_safe" "$RUNTIME_DIR/phase1_work"
    cp "$RUNTIME_DIR/phase2_advanced" "$RUNTIME_DIR/phase2_work"
    cp "$RUNTIME_DIR/phase3_risky" "$RUNTIME_DIR/phase3_work"
    cp "$RUNTIME_DIR/phase4_hidden" "$RUNTIME_DIR/phase4_work"

    if [ "$ms_choice" = "R" ]; then
        MODE_NAME="RESTORE"
        MODE_VERB="Restore"
        cat "$RUNTIME_DIR/phase4_hidden" "$RUNTIME_DIR/restore_only" > "$RUNTIME_DIR/phase4_work"
    else
        if [ "$DISABLE_MODE" = "1" ]; then
            MODE_NAME="FREEZE"
            MODE_VERB="Freeze"
        else
            MODE_NAME="SAFE_REMOVE"
            MODE_VERB="Safe Remove"
        fi

        case "$(printf '%s' "$JOYOSE_ACTION" | tr '[:lower:]' '[:upper:]')" in
            ASK)
                clear_screen
                printf '\n%s  JOYOSE THERMAL MANAGEMENT%s\n' "$BG_YEL" "$RESET"
                printf '%scom.xiaomi.joyose%s manages thermal components. Some devices need it to prevent overheating.\n\n' "$TXT_WHT" "$RESET"
                printf 'Do you want to %s Joyose?\n' "$MODE_VERB"
                joyose_choice=$(read_choice "YN" "[Y]es - Remove it   [N]o - Keep it safe: ")
                if [ "$joyose_choice" = "Y" ]; then
                    {
                        printf '%s\n' "com.xiaomi.joyose"
                        cat "$RUNTIME_DIR/phase1_safe"
                    } > "$RUNTIME_DIR/phase1_work"
                else
                    printf '  -> %sJoyose kept.%s\n' "$TXT_GRN" "$RESET"
                    sleep 2
                fi
                ;;
            REMOVE)
                {
                    printf '%s\n' "com.xiaomi.joyose"
                    cat "$RUNTIME_DIR/phase1_safe"
                } > "$RUNTIME_DIR/phase1_work"
                ;;
        esac
    fi

    if [ "$SHOW_PREVIEW" = "1" ]; then
        clear_screen
        printf '%s  SAFE LIST (PHASE 1)%s\n' "$BG_GRN" "$RESET"
        while IFS= read -r preview_pkg; do
            [ -n "$preview_pkg" ] && printf '  - %s\n' "$preview_pkg"
        done < "$RUNTIME_DIR/phase1_work"
        printf '\n%s  Press Enter to begin processing...%s' "$TXT_GRAY" "$RESET"
        IFS= read -r _preview_answer
    fi

    process_phase "PHASE 1/4 | Ads, Analytics & Junk Services" "$BG_GRN" "$RUNTIME_DIR/phase1_work"
    phase_result=$?
    [ "$phase_result" -eq 2 ] && finish_task && return
    [ "$phase_result" -ne 0 ] && pause_screen && return

    process_phase "PHASE 2/4 | User Tools & Features" "$BG_YEL" "$RUNTIME_DIR/phase2_work"
    phase_result=$?
    [ "$phase_result" -eq 2 ] && finish_task && return
    [ "$phase_result" -ne 0 ] && pause_screen && return

    if [ "$PROTECT_CORE" = "1" ] && [ "$MODE_NAME" != "RESTORE" ]; then
        clear_screen
        printf '%s  PHASE 3/4 | Risky System Apps%s\n\n' "$BG_RED" "$RESET"
        printf '%s[!] Protect Core System Apps is ENABLED in config.%s\n' "$TXT_YEL" "$RESET"
        printf '%sSkipping Phase 3 to prevent potential bootloops.%s\n' "$TXT_GRAY" "$RESET"
        sleep 3
    else
        process_phase "PHASE 3/4 | Risky System Apps" "$BG_RED" "$RUNTIME_DIR/phase3_work"
        phase_result=$?
        [ "$phase_result" -eq 2 ] && finish_task && return
        [ "$phase_result" -ne 0 ] && pause_screen && return
    fi

    process_phase "PHASE 4/4 | Hidden System Apps" "$BG_MAG" "$RUNTIME_DIR/phase4_work"
    phase_result=$?
    [ "$phase_result" -ne 0 ] && [ "$phase_result" -ne 2 ] && pause_screen && return
    finish_task
}

finish_task() {
    clear_screen
    printf '\n%s  TASK COMPLETED%s\n\n' "$BG_CYAN" "$RESET"
    cache_device_state
    pause_screen
}

main_menu() {
    while :; do
        clear_screen
        printf '\n%s====================================================================================================================%s\n' "$TXT_GRAY" "$RESET"
        printf '%s  MAIN MENU %s-%s Select Functionality%s\n' "$BOLD$TXT_WHT" "$TXT_CYAN" "$TXT_WHT" "$RESET"
        printf '%s====================================================================================================================%s\n\n' "$TXT_GRAY" "$RESET"
        printf '%s[1] Standard Debloat (Phases 1-4)%s\n' "$TXT_GRN" "$RESET"
        printf '%s[2] Interactive App Explorer%s\n' "$TXT_CYAN" "$RESET"
        printf '%s[3] Refresh Device Cache%s\n' "$TXT_YEL" "$RESET"
        printf '%s[E] Return to Manager%s\n\n' "$TXT_RED" "$RESET"

        mm_choice=$(read_choice "123E" "Choice: ")
        case "$mm_choice" in
            1) mode_select ;;
            2) interactive_explorer ;;
            3) cache_device_state || pause_screen ;;
            E) return ;;
        esac
    done
}

if [ "$FORCE_ADB" = "1" ] && [ "$SIM_MODE" != "1" ]; then
    adb_run kill-server >/dev/null 2>&1
fi

if [ "$SIM_MODE" != "1" ] || command -v "$ADB_CMD" >/dev/null 2>&1 || [ -x "$ADB_CMD" ]; then
    adb_run start-server >/dev/null 2>&1 || true
fi

wait_for_device
main_menu
