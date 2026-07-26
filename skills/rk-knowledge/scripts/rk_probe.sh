#!/bin/bash
# rk_probe.sh — Read-only identity probe for Rockchip RK35xx boards.
#
# Reads live /proc/device-tree/model, /proc/device-tree/compatible,
# /proc/version to answer "which RK board am I on?" deterministically,
# so the agent doesn't guess from memory.
#
# Output: JSON {"model":"...", "soc":"...", "kernel":"..."}
# Non-RK environment: {"error":"not_on_rk"}
#
# Principles: read-only (no writes to /sys or /proc); idempotent; bash-only (no jq dep).
# Usage: bash rk_probe.sh

set -euo pipefail

# --- Check if we're on a Rockchip board ---
is_rk=false
if grep -qi 'rockchip' /proc/device-tree/compatible 2>/dev/null; then
    is_rk=true
elif grep -qi 'rockchip' /proc/device-tree/model 2>/dev/null; then
    is_rk=true
elif grep -qi 'rk35' /proc/device-tree/model 2>/dev/null; then
    is_rk=true
fi

if [ "$is_rk" = false ]; then
    echo '{"error":"not_on_rk"}'
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

# --- SoC compatible string (e.g. "rockchip,rk3588") ---
soc=$(read_file /proc/device-tree/compatible)

# --- Kernel version ---
kernel=$(read_file /proc/version)

# --- NPU driver check (dmesg rknpu, non-fatal) ---
npu_driver=""
if dmesg 2>/dev/null | grep -qi 'rknpu'; then
    npu_driver="detected"
else
    npu_driver="not_detected"
fi

# --- Emit JSON ---
echo "{"
echo "  \"model\": \"${model}\","
echo "  \"soc\": \"${soc}\","
echo "  \"kernel\": \"${kernel}\","
echo "  \"npu_driver\": \"${npu_driver}\""
echo "}"
