#!/bin/bash
# bpu_status.sh — Read-only BPU and memory status probe for RDK boards.
#
# Reads live BPU frequency, memory, and utilization to answer "is the BPU
# actually working / how much headroom do I have?" without guessing.
#
# Output: JSON {"ok":true,"off_platform":false,"reason":"","fields":{"board_id":"...","bpu_ratio":"...","mem_total":"...","mem_free":"...","bpu_util":"..."}}
# Non-board: {"ok":false,"off_platform":true,"reason":"not_on_rdk_board: /sys/class/socinfo not found","fields":null}
# Board but hrut_bpuprofile missing: reason set to "hrut_bpuprofile not found"
#
# Principles: read-only; idempotent; bash-only.
# hrut_bpuprofile may not exist → graceful degradation (field omitted).
# Usage: bash bpu_status.sh

set -euo pipefail

# --- Check if we're on an RDK board ---
if [ ! -d /sys/class/socinfo ]; then
    echo '{"ok":false,"off_platform":true,"reason":"not_on_rdk_board: /sys/class/socinfo not found","fields":null}'
    exit 0
fi

# --- Helper: read a sysfs file safely ---
read_sysfs() {
    local path="$1"
    if [ -r "$path" ]; then
        cat "$path" 2>/dev/null | tr -d '\0' | tr -d '\n'
    else
        echo ""
    fi
}

# --- Board identity ---
board_id=$(read_sysfs /sys/class/socinfo/board_id)

# --- BPU frequency ratio ---
bpu_ratio=$(read_sysfs /sys/devices/system/bpu/bpu0/ratio)

# --- Memory from /proc/meminfo (more parseable than free -h) ---
mem_total=""
mem_free=""
if [ -r /proc/meminfo ]; then
    mem_total=$(awk '/^MemTotal:/{print $2" "$3}' /proc/meminfo 2>/dev/null | tr -d '\n')
    mem_free=$(awk '/^MemAvailable:/{print $2" "$3}' /proc/meminfo 2>/dev/null | tr -d '\n')
fi

# --- BPU utilization (hrut_bpuprofile may not exist) ---
bpu_util=""
bpu_note=""
if command -v hrut_bpuprofile >/dev/null 2>&1; then
    # Capture a 1-second snapshot; extract utilization if parseable
    bpu_util=$(timeout 3 hrut_bpuprofile -b 0 2>/dev/null | head -5 | tr -d '\n' | sed 's/"/\\\"/g')
    [ -z "$bpu_util" ] && bpu_util="unavailable"
else
    bpu_util="hrut_bpuprofile_not_found"
    bpu_note="hrut_bpuprofile not found"
fi

# --- Emit JSON (contract: ok/off_platform/reason/fields) ---
echo '{"ok":true,"off_platform":false,"reason":"'"${bpu_note}"'","fields":{'
echo "  \"board_id\": \"${board_id}\","
echo "  \"bpu_ratio\": \"${bpu_ratio}\","
echo "  \"mem_total\": \"${mem_total}\","
echo "  \"mem_free\": \"${mem_free}\","
echo "  \"bpu_util\": \"${bpu_util}\""
echo '}}'
