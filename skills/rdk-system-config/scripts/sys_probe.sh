#!/bin/bash
# sys_probe.sh — Read-only system configuration probe for RDK boards.
#
# Reads network interfaces, boot config, CPU governor, and gateway
# connectivity — so the agent can verify "is the network up / what's the
# current CPU mode" without guessing.
#
# Output: JSON {"interfaces":[...], "config_txt_exists":true|false,
#                "cpu_governor":"...", "gateway_reachable":true|false}
# Non-board environment: {"error":"not_on_board"}
#
# Principles: read-only (no config writes); ping limited to 1 packet 1s timeout;
# idempotent; bash-only.
# Usage: bash sys_probe.sh

set -euo pipefail

# --- Check if we're on an RDK board ---
if [ ! -d /sys/class/socinfo ]; then
    echo '{"error":"not_on_board"}'
    exit 0
fi

# --- Network interfaces (names only, UP ones) ---
interfaces=""
if command -v ip >/dev/null 2>&1; then
    # List interface names that are UP, exclude lo
    interfaces=$(ip -o link show 2>/dev/null | awk '$2 != "lo" && $9 == "UP" {print $2}' | tr '\n' ' ' | sed 's/ /", "/g; s/^/"/; s/", "$//')
fi
[ -z "$interfaces" ] && interfaces="\"none\""

# --- /boot/config.txt existence ---
config_txt_exists="false"
if [ -f /boot/config.txt ]; then
    config_txt_exists="true"
fi

# --- CPU governor ---
cpu_governor=""
gov_path="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
if [ -r "$gov_path" ]; then
    cpu_governor=$(cat "$gov_path" 2>/dev/null | tr -d '\n')
fi
[ -z "$cpu_governor" ] && cpu_governor="unknown"

# --- Gateway reachability (ping -c1 -W1, 1 packet 1s timeout) ---
gateway_reachable="false"
gateway_ip=""
if command -v ip >/dev/null 2>&1; then
    gateway_ip=$(ip route 2>/dev/null | awk '/^default/ {print $3; exit}')
fi
if [ -n "$gateway_ip" ]; then
    if ping -c 1 -W 1 "$gateway_ip" >/dev/null 2>&1; then
        gateway_reachable="true"
    fi
fi

# --- Emit JSON ---
echo "{"
echo "  \"interfaces\": [${interfaces}],"
echo "  \"config_txt_exists\": ${config_txt_exists},"
echo "  \"cpu_governor\": \"${cpu_governor}\","
echo "  \"gateway_reachable\": ${gateway_reachable}"
echo "}"
