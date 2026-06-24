# TROS/ROS2 命令

> 来源:整理自 D-Robotics RDK 官方文档、工具链与社区实践,逐条保留出处链接;由 device-knowledge 知识库忠实转换而来,未改写技术事实。

## ROS2 / TROS 命令

| 命令模式 | 说明 | 风险 | 适用板型 |
| --- | --- | --- | --- |
| `ros2\s+launch` | ROS2 launch file execution | moderate | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+run` | ROS2 run single node | moderate | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+topic` | ROS2 topic inspection | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+node` | ROS2 node inspection | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+param` | ROS2 parameter query/set | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+service` | ROS2 service call/list | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+action` | ROS2 action send goal / list | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+pkg` | ROS2 package query | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+interface` | ROS2 interface (msg/srv) show | safe | x3/x5/ultra/s100/s100p/s600 |
| `ros2\s+bag` | ROS2 bag record/play | moderate | x3/x5/ultra/s100/s100p/s600 |
| `source\s+\/opt\/tros` | TROS environment setup | safe | x3/x5/ultra/s100/s100p/s600 |
| `colcon\s+build` | ROS2 workspace build | moderate | x3/x5/ultra/s100/s100p/s600 |
| `rosdep\s+install` | ROS2 dependency install | moderate | x3/x5/ultra/s100/s100p/s600 |
