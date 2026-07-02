#!/bin/sh

# Shared helpers for the Unix shell implementation. This file is sourced by the
# Linux/macOS scripts and intentionally sticks to POSIX sh plus standard tools.

: "${ROOT_DIR:=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)}"

CONFIG_DIR="$ROOT_DIR/data/config"
CONFIG_PATH="$CONFIG_DIR/config.json"
CONFIG_DEFAULT_PATH="$CONFIG_DIR/config_default.json"
SERVICES_PATH="$CONFIG_DIR/services.json"
LOGS_DIR="$ROOT_DIR/logs"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    ESC=$(printf '\033')
    RESET="${ESC}[0m"
    BOLD="${ESC}[1m"
    BG_CYAN="${ESC}[46m${ESC}[30m"
    BG_MAG="${ESC}[45m${ESC}[30m"
    BG_GRN="${ESC}[42m${ESC}[30m"
    BG_YEL="${ESC}[43m${ESC}[30m"
    BG_RED="${ESC}[41m${ESC}[97m"
    TXT_CYAN="${ESC}[96m"
    TXT_GRN="${ESC}[92m"
    TXT_YEL="${ESC}[93m"
    TXT_RED="${ESC}[91m"
    TXT_MAG="${ESC}[95m"
    TXT_GRAY="${ESC}[90m"
    TXT_WHT="${ESC}[97m"
else
    RESET=
    BOLD=
    BG_CYAN=
    BG_MAG=
    BG_GRN=
    BG_YEL=
    BG_RED=
    TXT_CYAN=
    TXT_GRN=
    TXT_YEL=
    TXT_RED=
    TXT_MAG=
    TXT_GRAY=
    TXT_WHT=
fi

clear_screen() {
    if command -v clear >/dev/null 2>&1; then
        clear
    else
        printf '\033[2J\033[H'
    fi
}

pause_screen() {
    printf '\nPress Enter to continue... '
    IFS= read -r _pause_answer
}

read_choice() {
    hc_allowed=$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')
    hc_prompt=$2

    while :; do
        printf '%s' "$hc_prompt" >&2
        IFS= read -r hc_answer || exit 1
        hc_answer=$(printf '%s' "$hc_answer" | tr '[:lower:]' '[:upper:]' | cut -c 1)
        if [ -n "$hc_answer" ]; then
            case "$hc_allowed" in
                *"$hc_answer"*)
                    printf '%s\n' "$hc_answer"
                    return 0
                    ;;
            esac
        fi
        printf 'Invalid choice. Try again.\n' >&2
    done
}

report_error() {
    printf '%s[!] %s%s\n' "$TXT_RED" "$1" "$RESET" >&2
    if [ -n "${LOGFILE:-}" ] && [ "$LOGFILE" != "/dev/null" ]; then
        printf '%s | ERROR | %s\n' "$(date '+%H:%M:%S')" "$1" >> "$LOGFILE"
    fi
}

ensure_config() {
    if [ ! -f "$CONFIG_PATH" ]; then
        if [ ! -r "$CONFIG_DEFAULT_PATH" ]; then
            report_error "Default config is missing or unreadable: CONFIG_DEFAULT_PATH=$CONFIG_DEFAULT_PATH"
            exit 1
        fi
        if ! mkdir -p "$CONFIG_DIR"; then
            report_error "Unable to create config directory: CONFIG_DIR=$CONFIG_DIR"
            exit 1
        fi
        if ! cp "$CONFIG_DEFAULT_PATH" "$CONFIG_PATH"; then
            report_error "Unable to copy CONFIG_DEFAULT_PATH=$CONFIG_DEFAULT_PATH to CONFIG_PATH=$CONFIG_PATH"
            exit 1
        fi
    fi
}

config_get() {
    awk -v key="$1" '
        /"settings"[[:space:]]*:/ {
            in_settings = 1
            next
        }
        in_settings && /^[[:space:]]*}/ {
            exit
        }
        in_settings {
            line = $0
            if (line ~ "\"" key "\"[[:space:]]*:") {
                sub(/^[^:]*:[[:space:]]*/, "", line)
                sub(/[[:space:]]*,[[:space:]]*$/, "", line)
                sub(/^"/, "", line)
                sub(/"$/, "", line)
                print line
                exit
            }
        }
    ' "$CONFIG_PATH"
}

config_bool() {
    cb_value=$(config_get "$1" | tr '[:upper:]' '[:lower:]')
    case "$cb_value" in
        true|1|yes|on) printf '1\n' ;;
        *) printf '0\n' ;;
    esac
}

config_set_value() {
    csv_key=$1
    csv_value=$2
    csv_type=$3
    csv_tmp=$(mktemp "${TMPDIR:-/tmp}/hyperos_config.XXXXXX") || exit 1

    awk -v key="$csv_key" -v value="$csv_value" -v value_type="$csv_type" '
        /"settings"[[:space:]]*:/ {
            in_settings = 1
        }
        in_settings && $0 ~ "\"" key "\"[[:space:]]*:" {
            indent = $0
            sub(/"[^"]+".*/, "", indent)
            comma = ($0 ~ /,[[:space:]]*$/) ? "," : ""
            if (value_type == "string") {
                print indent "\"" key "\": \"" value "\"" comma
            } else {
                print indent "\"" key "\": " value comma
            }
            next
        }
        {
            print
        }
        in_settings && /^[[:space:]]*}/ {
            in_settings = 0
        }
    ' "$CONFIG_PATH" > "$csv_tmp" && mv "$csv_tmp" "$CONFIG_PATH"
}

config_set_bool() {
    if [ "$2" = "1" ]; then
        config_set_value "$1" "true" "bool"
    else
        config_set_value "$1" "false" "bool"
    fi
}

config_set_string() {
    config_set_value "$1" "$2" "string"
}

phase_packages() {
    awk -v phase="$1" '
        $0 ~ "\"" phase "\"[[:space:]]*:" {
            in_phase = 1
        }
        in_phase {
            line = $0
            while (match(line, /"[^"]+"/)) {
                pkg = substr(line, RSTART + 1, RLENGTH - 2)
                if (pkg != phase) {
                    print pkg
                }
                line = substr(line, RSTART + RLENGTH)
            }
            if ($0 ~ /\]/) {
                exit
            }
        }
    ' "$SERVICES_PATH"
}

description_map() {
    awk '
        /"descriptions"[[:space:]]*:[[:space:]]*{/ {
            in_desc = 1
            next
        }
        in_desc && /^[[:space:]]*}/ {
            exit
        }
        in_desc {
            split($0, parts, "\"")
            if (parts[2] != "" && parts[4] != "") {
                print parts[2] "\t" parts[4]
            }
        }
    ' "$SERVICES_PATH"
}

prepare_runtime() {
    RUNTIME_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hyperos_debloater.XXXXXX") || exit 1
    trap 'rm -rf "$RUNTIME_DIR"' EXIT HUP INT TERM

    prepare_phase_file "phase1_safe" "$RUNTIME_DIR/phase1_safe" || return 1
    prepare_phase_file "phase2_advanced" "$RUNTIME_DIR/phase2_advanced" || return 1
    prepare_phase_file "phase3_risky" "$RUNTIME_DIR/phase3_risky" || return 1
    prepare_phase_file "phase4_hidden" "$RUNTIME_DIR/phase4_hidden" || return 1
    prepare_phase_file "restore_only" "$RUNTIME_DIR/restore_only" || return 1

    if ! description_map > "$RUNTIME_DIR/descriptions.tsv"; then
        report_error "prepare_runtime failed: description_map could not write $RUNTIME_DIR/descriptions.tsv"
        return 1
    fi
    if [ ! -s "$RUNTIME_DIR/descriptions.tsv" ]; then
        report_error "prepare_runtime failed: description_map produced an empty $RUNTIME_DIR/descriptions.tsv"
        return 1
    fi
}

prepare_phase_file() {
    ppf_phase=$1
    ppf_output=$2

    if ! phase_packages "$ppf_phase" > "$ppf_output"; then
        report_error "prepare_runtime failed: phase_packages $ppf_phase could not write $ppf_output in RUNTIME_DIR=$RUNTIME_DIR"
        return 1
    fi
    if [ ! -s "$ppf_output" ]; then
        report_error "prepare_runtime failed: phase_packages $ppf_phase produced an empty $ppf_output in RUNTIME_DIR=$RUNTIME_DIR"
        return 1
    fi
}

app_label() {
    awk -F '\t' -v pkg="$1" '
        $1 == pkg {
            print $2
            found = 1
            exit
        }
        END {
            if (!found) {
                print pkg
            }
        }
    ' "$RUNTIME_DIR/descriptions.tsv"
}

resolve_adb() {
    ADB_PATH=$(config_get "defaultAdbPath")
    [ -n "$ADB_PATH" ] || ADB_PATH="adb"

    if [ -f "$ROOT_DIR/$ADB_PATH" ]; then
        ADB_CMD="$ROOT_DIR/$ADB_PATH"
    elif [ "$ADB_PATH" = "adb.exe" ]; then
        ADB_CMD="adb"
    else
        ADB_CMD="$ADB_PATH"
    fi
}

require_adb() {
    resolve_adb
    if [ "$SIM_MODE" = "1" ]; then
        return 0
    fi
    if ! command -v "$ADB_CMD" >/dev/null 2>&1 && [ ! -x "$ADB_CMD" ]; then
        printf '%s[!] ADB was not found.%s\n' "$TXT_RED" "$RESET"
        printf 'Install Android platform-tools or set settings.defaultAdbPath in %s.\n' "$CONFIG_PATH"
        exit 1
    fi
}

adb_run() {
    "$ADB_CMD" "$@"
}

load_runtime_settings() {
    JOYOSE_ACTION=$(config_get "joyoseAction")
    SKIP_NOT_INSTALLED=$(config_bool "smartFiltering")
    SHOW_PREVIEW=$(config_bool "showPreview")
    LOG_ENABLED=$(config_bool "logToText")
    SIM_MODE=$(config_bool "simulationMode")
    DISABLE_MODE=$(config_bool "disableInsteadOfUninstall")
    PROTECT_CORE=$(config_bool "skipSystemCore")
    FORCE_ADB=$(config_bool "forceADBRestart")
    REBOOT_RESTORE=$(config_bool "rebootAfterRestore")
}

start_log() {
    LOGFILE=/dev/null
    if [ "$LOG_ENABLED" = "1" ]; then
        mkdir -p "$LOGS_DIR"
        safe_date=$(date '+%Y-%m-%d_%H-%M-%S')
        LOGFILE="$LOGS_DIR/Debloat_Log_$safe_date.log"
        {
            printf '[LOG STARTED]\n'
            printf 'Target OS: Xiaomi HyperOS\n'
            printf 'Date: %s\n' "$(date)"
            printf '%s\n' '--------------------------------------------------------'
        } > "$LOGFILE"
    fi
}

log_action() {
    printf '%s | %s | %s\n' "$(date '+%H:%M:%S')" "$1" "$2" >> "$LOGFILE"
}

status_label() {
    if [ "$1" = "1" ]; then
        printf '%sON %s' "$TXT_GRN" "$RESET"
    else
        printf '%sOFF%s' "$TXT_RED" "$RESET"
    fi
}

bool_toggle() {
    if [ "$1" = "1" ]; then
        printf '0\n'
    else
        printf '1\n'
    fi
}
