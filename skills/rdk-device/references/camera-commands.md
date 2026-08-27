# RDK Camera Commands

> Source: compiled from official D-Robotics RDK documentation, the toolchain, and reproduced community practice; provenance preserved per item. Faithfully derived from the device-knowledge base — no technical facts altered.

## Camera-related commands

| Command pattern | Purpose | Risk | Applicable boards |
| --- | --- | --- | --- |
| `v4l2-ctl` | V4L2 camera control / capability query | safe | x3 / x5 / ultra / s100 / s100p |
| `lsusb` | USB device enumeration (camera detection) | safe | x3 / x5 / ultra / s100 / s100p |
| `ls /dev/video*` | Camera device-file listing | safe | x3 / x5 / ultra / s100 / s100p |

## X5 MIPI and OV08D: no `/dev/video*` assumption

The X5 camera stack can expose VIN, ISP, and MIPI character devices such as
`/dev/vin*_cap`, `/dev/vs-isp*_cap`, and `/dev/mipi_host*` without exposing a
V4L2 `/dev/video*` node. Therefore, absence of `/dev/video*` is not by itself an
OV08D failure.

Run the repository probe from the `rdk-device` skill directory:

```bash
bash scripts/ov08d_probe.sh
```

Interpret its evidence classes independently:

- `plugin_installed` and `tuning_modes` prove only that the installed
  `hobot-camera` package has OV08D support. They do not prove hardware presence.
- `active_sensor_identity` is observed only from an active `mipi_cam` ROS
  parameter/process/log. An empty value must remain unknown.
- `vin_nodes`, `isp_nodes`, and `mipi_nodes` show that the X5 media pipeline
  devices exist; they do not identify the connected sensor.
- `requested_width`, `requested_height`, `requested_format`, and
  `requested_io_method` describe the active ROS producer contract when one is
  running.
- `image_topic`, `publisher_count`, and `fresh_frame` are separate live
  evidence. A topic name without a publisher or a bounded fresh sample does not
  prove capture health.

For the validated engineering case, the intended producer contract is OV08D at
1920x1080, NV12, shared memory, then an explicit resize to the model's 640x640
input. Query the live node before inference:

```bash
source /opt/tros/humble/setup.bash
ros2 param get /mipi_cam video_device
ros2 param get /mipi_cam image_width
ros2 param get /mipi_cam image_height
ros2 param get /mipi_cam out_format
ros2 param get /mipi_cam io_method
ros2 topic info /hbmem_img --verbose
timeout 8 ros2 topic echo /hbmem_img --once
```

These are read-only queries. Starting or restarting `mipi_cam`, changing the
sensor/mode, or interrupting another camera consumer is a device mutation and
requires explicit approval and exclusive camera ownership.
