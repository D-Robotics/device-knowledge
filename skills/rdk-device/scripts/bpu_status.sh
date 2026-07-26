#!/bin/bash
# bpu_status.sh — Read-only BPU and memory status probe for RDK boards.
#
# Reads live BPU frequency, memory, and utilization to answer "is the BPU
# actually working / how much headroom do I have?" without guessing.
#
# Output: JSON {"board_id":"...", "bpu_ratio":"...", "mem_total":"...",
#                "mem_free":"...", "bpu_util":"..."}
# Non-board environment: {"error":"not_on_board"}
#
# Principles: read-only; idempotent; bash-only.
# hrut_bpuprofile may not exist → graceful degradation (field omitted).
# Usage: bash bpu_status.sh

set -euo pipefail

# --- Check if we're on an RDK board ---
if [ ! -d /sys/class/socinfo ]; then
    echo '{"error":"not_on_board"}'
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
if command -v hrut_bpuprofile >/dev/null 2>&1; then
    # Capture a 1-second snapshot; extract utilization if parseable
    bpu_util=$(timeout 3 hrut_bpuprofile -b 0 2>/dev/null | head -5 | tr -d '\n' | sed 's/"/\\"/g')
    [ -z "$bpu_util" ] && bpu_util="unavailable"
else
    bpu_util="hrut_bpuprofile_not_found"
fi

# --- Emit JSON ---
echo "{"
echo "  \"board_id\": \"${board_id}\","
echo "  \"bpu_ratio\": \"${bpu_ratio}\","
echo "  \"mem_total\": \"${mem_total}\","
echo "  \"mem_free\": \"${mem_free}\","
echo "  \"bpu_util\": \"${bpu_util}\""
echo "}"
