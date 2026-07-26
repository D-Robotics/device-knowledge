#!/bin/bash
# tros_check.sh — Read-only TROS/ROS2 environment probe for RDK boards.
#
# Detects which TROS distro is installed (humble vs jazzy), verifies ros2
# is available after sourcing, and counts installed packages — so the agent
# knows the environment is ready before advising launch commands.
#
# Output: JSON {"tros_distro":"humble|jazzy|none", "setup_path":"...",
#                "ros2_available":true|false, "packages_installed":N}
# Non-board environment: {"error":"not_on_board"}
#
# Principles: source in subshell (does NOT affect outer env); read-only (no
# installs); idempotent; bash-only.
# Usage: bash tros_check.sh

set -euo pipefail

# --- Detect TROS distro by checking which setup path exists ---
tros_distro="none"
setup_path=""
if [ -f /opt/tros/jazzy/setup.bash ]; then
    tros_distro="jazzy"
    setup_path="/opt/tros/jazzy/setup.bash"
elif [ -f /opt/tros/humble/setup.bash ]; then
    tros_distro="humble"
    setup_path="/opt/tros/humble/setup.bash"
fi

# --- If no TROS found, check if we're even on a board ---
if [ "$tros_distro" = "none" ]; then
    if [ ! -d /sys/class/socinfo ] && [ ! -d /opt/tros ]; then
        echo '{"error":"not_on_board"}'
        exit 0
    fi
    # On a board but TROS not installed
    echo "{"
    echo "  \"tros_distro\": \"none\","
    echo "  \"setup_path\": \"\","
    echo "  \"ros2_available\": false,"
    echo "  \"packages_installed\": 0"
    echo "}"
    exit 0
fi

# --- Source in subshell and verify ros2 availability ---
ros2_available="false"
packages_installed=0

# Run in subshell so source doesn't leak to outer environment
result=$(
    bash -c "
        source '${setup_path}' 2>/dev/null
        if command -v ros2 >/dev/null 2>&1; then
            echo 'true'
            ros2 pkg list 2>/dev/null | wc -l
        else
            echo 'false'
            echo '0'
        fi
    " 2>/dev/null
) || true

ros2_available=$(echo "$result" | head -1)
packages_installed=$(echo "$result" | tail -1)

# --- Emit JSON ---
echo "{"
echo "  \"tros_distro\": \"${tros_distro}\","
echo "  \"setup_path\": \"${setup_path}\","
echo "  \"ros2_available\": ${ros2_available},"
echo "  \"packages_installed\": ${packages_installed}"
echo "}"
