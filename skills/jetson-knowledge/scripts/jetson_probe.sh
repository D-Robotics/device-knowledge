#!/bin/bash
# jetson_probe.sh — Read-only identity probe for NVIDIA Jetson modules.
#
# Reads live /proc/device-tree/model, /etc/nv_tegra_release, nvidia-smi
# to answer "which Jetson am I on?" deterministically, so the agent
# doesn't guess from memory.
#
# Output: JSON {"model":"...", "jetpack":"...", "gpu_mem":"...", "cuda_cores":"..."}
# Non-Jetson environment: {"error":"not_on_jetson"}
#
# Principles: read-only (no writes to /sys or /proc); idempotent; bash-only (no jq dep).
# Usage: bash jetson_probe.sh

set -euo pipefail

# --- Check if we're on a Jetson ---
is_jetson=false
if [ -f /etc/nv_tegra_release ]; then
    is_jetson=true
elif grep -qi 'nvidia' /proc/device-tree/model 2>/dev/null; then
    is_jetson=true
elif grep -qi 'jetson' /proc/device-tree/model 2>/dev/null; then
    is_jetson=true
fi

if [ "$is_jetson" = false ]; then
    echo '{"error":"not_on_jetson"}'
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

# --- Read module model ---
model=$(read_file /proc/device-tree/model)

# --- JetPack / L4T version ---
jetpack=""
if [ -f /etc/nv_tegra_release ]; then
    jetpack=$(read_file /etc/nv_tegra_release | head -1)
fi

# --- GPU memory (nvidia-smi, JetPack 5+) ---
gpu_mem=""
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '\n')
    if [ -z "$gpu_mem" ]; then
        gpu_mem=""
    fi
fi

# --- CUDA cores (from nvidia-smi or tegrinfo if available) ---
cuda_cores=""
if command -v nvidia-smi >/dev/null 2>&1; then
    cores=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d '\n')
    if [ -n "$cores" ]; then
        cuda_cores="$cores"
    fi
fi
if [ -z "$cuda_cores" ] && command -v tegrinfo >/dev/null 2>&1; then
    cores=$(tegrinfo 2>/dev/null | grep -i 'cuda' | head -1 | tr -d '\n')
    if [ -n "$cores" ]; then
        cuda_cores="$cores"
    fi
fi

# --- Emit JSON ---
echo "{"
echo "  \"model\": \"${model}\","
echo "  \"jetpack\": \"${jetpack}\","
echo "  \"gpu_mem\": \"${gpu_mem}\","
echo "  \"cuda_cores\": \"${cuda_cores}\""
echo "}"
