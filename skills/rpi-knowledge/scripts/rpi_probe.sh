#!/bin/bash
# rpi_probe.sh — Read-only identity probe for Raspberry Pi boards.
#
# Reads live /proc/device-tree/model, /proc/cpuinfo (Revision),
# vcgencmd measure_clock arm to answer "which Pi am I on?" deterministically,
# so the agent doesn't guess from memory.
#
# Output: JSON {"model":"...", "revision":"...", "arm_clock":"..."}
# Non-Pi environment: {"error":"not_on_rpi"}
#
# Principles: read-only (no writes to /sys or /proc); idempotent; bash-only (no jq dep).
# Usage: bash rpi_probe.sh

set -euo pipefail

# --- Check if we're on a Raspberry Pi ---
is_rpi=false
if grep -qi 'raspberry pi' /proc/device-tree/model 2>/dev/null; then
    is_rpi=true
fi

if [ "$is_rpi" = false ]; then
    echo '{"error":"not_on_rpi"}'
    exit 0
fi

# --- Helper: read a file safely, strip trailing null/newline ---
read_file() {
    local path="$1"
    if [ -r "$path" ]; then
        cat "$path" 2>/dev/null | tr -d '\0' | tr -d '\n' | sed 's/\\/\\\\/g; s/"/\\"/g'
    else
        echo ""
    fi
}

# --- Read board model ---
model=$(read_file /proc/device-tree/model)

# --- Board revision from /proc/cpuinfo ---
revision=""
if [ -r /proc/cpuinfo ]; then
    revision=$(grep -i '^Revision' /proc/cpuinfo 2>/dev/null | head -1 | sed 's/.*: *//' | tr -d '\n')
fi

# --- ARM clock frequency (vcgencmd, non-fatal) ---
arm_clock=""
if command -v vcgencmd >/dev/null 2>&1; then
    arm_clock=$(vcgencmd measure_clock arm 2>/dev/null | head -1 | tr -d '\n')
    if [ -z "$arm_clock" ]; then
        arm_clock=""
    fi
fi

# --- Emit JSON ---
echo "{"
echo "  \"model\": \"${model}\","
echo "  \"revision\": \"${revision}\","
echo "  \"arm_clock\": \"${arm_clock}\""
echo "}"
