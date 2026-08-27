#!/bin/bash
# ov08d_probe.sh — read-only RDK X5 MIPI/OV08D evidence collector.
#
# It intentionally separates installed driver support from live sensor identity
# and live frame evidence. It never starts/stops a node or changes camera state.

set -euo pipefail

if [ ! -d /sys/class/socinfo ]; then
    echo '{"ok":false,"off_platform":true,"reason":"not_on_rdk_board","fields":null}'
    exit 0
fi

json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\r\n' '  '
}

count_glob() {
    find /dev -maxdepth 1 -type c -name "$1" 2>/dev/null | wc -l | tr -d ' '
}

board_id=$(tr -d '\0\r\n' </sys/class/socinfo/board_id 2>/dev/null || true)
cam_service=$(systemctl is-active cam-service 2>/dev/null || true)
cam_service_version=$(/usr/hobot/bin/cam-service -v 2>/dev/null | head -n 1 || true)
plugin_installed=false
[ -e /usr/hobot/lib/sensor/libov08d.so ] && plugin_installed=true
tuning_modes=$(find /usr/hobot/lib/sensor -maxdepth 1 -type f -name 'ov08d_*x*_tuning.json' -printf '%f\n' 2>/dev/null | sort | paste -sd, -)
vin_nodes=$(count_glob 'vin*')
isp_nodes=$(count_glob 'vs-isp*')
mipi_nodes=$(count_glob 'mipi*')

active_sensor_identity=""
requested_width=""
requested_height=""
requested_format=""
requested_io_method=""
image_topic=""
publisher_count="0"
fresh_frame=false

if [ -r /opt/tros/humble/setup.bash ]; then
    set +u
    source /opt/tros/humble/setup.bash >/dev/null 2>&1 || true
    set -u
    nodes=$(timeout 5 ros2 node list 2>/dev/null || true)
    mipi_node=$(printf '%s\n' "$nodes" | grep -E '/?(mipi_cam|hobot_mipi_cam)$' | head -n 1 || true)
    if [ -n "$mipi_node" ]; then
        param_value() {
            timeout 5 ros2 param get "$mipi_node" "$1" 2>/dev/null | sed -E 's/^[A-Za-z0-9_ ]+ value is: //' | head -n 1
        }
        active_sensor_identity=$(param_value video_device || true)
        requested_width=$(param_value image_width || true)
        requested_height=$(param_value image_height || true)
        requested_format=$(param_value out_format || true)
        requested_io_method=$(param_value io_method || true)
    fi
    topics=$(timeout 5 ros2 topic list 2>/dev/null || true)
    image_topic=$(printf '%s\n' "$topics" | grep -E '^/(hbmem_img|image_raw|image)$' | head -n 1 || true)
    if [ -n "$image_topic" ]; then
        publisher_count=$(timeout 5 ros2 topic info "$image_topic" 2>/dev/null | awk -F: '/Publisher count/{gsub(/ /,"",$2); print $2; exit}')
        publisher_count=${publisher_count:-0}
        if [ "$publisher_count" -gt 0 ] 2>/dev/null && timeout 8 ros2 topic echo "$image_topic" --once >/dev/null 2>&1; then
            fresh_frame=true
        fi
    fi
fi

cat <<JSON
{"ok":true,"off_platform":false,"reason":"","fields":{
  "board_id":"$(json_escape "$board_id")",
  "cam_service":"$(json_escape "$cam_service")",
  "cam_service_version":"$(json_escape "$cam_service_version")",
  "plugin_installed":${plugin_installed},
  "tuning_modes":"$(json_escape "$tuning_modes")",
  "vin_nodes":${vin_nodes},
  "isp_nodes":${isp_nodes},
  "mipi_nodes":${mipi_nodes},
  "active_sensor_identity":"$(json_escape "$active_sensor_identity")",
  "requested_width":"$(json_escape "$requested_width")",
  "requested_height":"$(json_escape "$requested_height")",
  "requested_format":"$(json_escape "$requested_format")",
  "requested_io_method":"$(json_escape "$requested_io_method")",
  "image_topic":"$(json_escape "$image_topic")",
  "publisher_count":${publisher_count},
  "fresh_frame":${fresh_frame}
}}
JSON
