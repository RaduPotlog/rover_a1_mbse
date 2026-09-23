  package RoverA1 {
    library package RoverProfile {
      metadata def RosTopic {
        attribute topic : $::ScalarValues::String default := "";
        attribute msgType : $::ScalarValues::String default := "";
        attribute qos : $::ScalarValues::String default := "";
      }
    }
    library package RoverA1Interfaces {
      port def BatteryStatus {
        out attribute stateOfCharge : $::ScalarValues::Real;
        out attribute temperature : $::ScalarValues::Real;
      }
      port def CrsfFrame;
      port def ElectricPower;
      port def Imu;
      port def LaserScan;
      port def ModbusFrame;
      port def NavSatFix {
        out attribute horizontalStd : $::ScalarValues::Real;
      }
      port def Odometry {
        out attribute x : $::ScalarValues::Real;
        out attribute y : $::ScalarValues::Real;
        out attribute yaw : $::ScalarValues::Real;
      }
      port def PointCloud2;
      port def TwistStamped {
        out attribute linearX : $::ScalarValues::Real;
        out attribute angularZ : $::ScalarValues::Real;
      }
      port def WheelVelocityCommand {
        out attribute wheelSpeed : $::ScalarValues::Real;
      }
    }
    part def RoverA1Arch {
      attribute averageLoad : $::ScalarValues::Real default := 160;
      attribute bodyMass : $::ScalarValues::Real default := 33.45;
      attribute wheelSeparation : $::ScalarValues::Real default := 0.62602;
      attribute wheelbase : $::ScalarValues::Real default := 0.5084;
      part sensors {
        part scanProjection {
          out port scanOut: $::RoverA1::RoverA1Interfaces::LaserScan;
          in port cloudIn: ~$::RoverA1::RoverA1Interfaces::PointCloud2;
        }
        out port scanProjection_scanOut: $::RoverA1::RoverA1Interfaces::LaserScan;
        in port scanProjection_cloudIn: ~$::RoverA1::RoverA1Interfaces::PointCloud2;
        connect scanProjection.scanOut to scanProjection_scanOut;
        connect scanProjection_cloudIn to scanProjection.cloudIn;
      }
      part safetyController {
        attribute watchdogPeriod : $::ScalarValues::Real default := 0.2;
        in port modbus: ~$::RoverA1::RoverA1Interfaces::ModbusFrame;
      }
      part rc {
        out port crsfOut: $::RoverA1::RoverA1Interfaces::CrsfFrame;
      }
      part platform {
        part twistMux {
          attribute inputTimeout : $::ScalarValues::Real default := 0.5;
          in port webIn: ~$::RoverA1::RoverA1Interfaces::TwistStamped;
          in port rcIn: ~$::RoverA1::RoverA1Interfaces::TwistStamped;
          in port navIn: ~$::RoverA1::RoverA1Interfaces::TwistStamped;
          out port cmdOut: $::RoverA1::RoverA1Interfaces::TwistStamped;
        }
        part safetyManager {
          attribute batteryEstopTemperature : $::ScalarValues::Real default := 323.15;
          attribute batteryShutdownTemperature : $::ScalarValues::Real default := 333.15;
          out port modbus: $::RoverA1::RoverA1Interfaces::ModbusFrame;
          in port batteryIn: ~$::RoverA1::RoverA1Interfaces::BatteryStatus;
        }
        part localization {
          attribute ekfRate : $::ScalarValues::Real default := 50;
          in port wheelOdomIn: ~$::RoverA1::RoverA1Interfaces::Odometry;
          out port odomOut: $::RoverA1::RoverA1Interfaces::Odometry;
          in port imuIn: ~$::RoverA1::RoverA1Interfaces::Imu;
          in port fixIn: ~$::RoverA1::RoverA1Interfaces::NavSatFix;
        }
        part driveController {
          attribute cmdTimeout : $::ScalarValues::Real default := 0.5;
          attribute maxAngularSpeed : $::ScalarValues::Real default := 1.0;
          attribute maxLinearAccel : $::ScalarValues::Real default := 2.7;
          attribute maxLinearSpeed : $::ScalarValues::Real default := 1.2;
          attribute updateRate : $::ScalarValues::Real default := 100;
          out port odomOut: $::RoverA1::RoverA1Interfaces::Odometry;
          in port cmdIn: ~$::RoverA1::RoverA1Interfaces::TwistStamped;
        }
        part crsfTeleop {
          in port crsfIn: ~$::RoverA1::RoverA1Interfaces::CrsfFrame;
          out port cmdOut: $::RoverA1::RoverA1Interfaces::TwistStamped;
        }
        part batteryMonitor {
          out port statusOut: $::RoverA1::RoverA1Interfaces::BatteryStatus;
          in port bmsIn: ~$::RoverA1::RoverA1Interfaces::BatteryStatus;
        }
        in port twistMux_webIn: ~$::RoverA1::RoverA1Interfaces::TwistStamped;
        in port twistMux_navIn: ~$::RoverA1::RoverA1Interfaces::TwistStamped;
        out port localization_odomOut: $::RoverA1::RoverA1Interfaces::Odometry;
        in port localization_imuIn: ~$::RoverA1::RoverA1Interfaces::Imu;
        in port localization_fixIn: ~$::RoverA1::RoverA1Interfaces::NavSatFix;
        in port crsfTeleop_crsfIn: ~$::RoverA1::RoverA1Interfaces::CrsfFrame;
        out port batteryMonitor_statusOut: $::RoverA1::RoverA1Interfaces::BatteryStatus;
        in port batteryMonitor_bmsIn: ~$::RoverA1::RoverA1Interfaces::BatteryStatus;
        connect driveController.odomOut to localization.wheelOdomIn {
          @$::RoverA1::RoverProfile::RosTopic {
            msgType = "nav_msgs/Odometry";
            qos = "Reliable";
            topic = "odometry/wheels";
          }
        }
        connect batteryMonitor.statusOut to batteryMonitor_statusOut;
        connect batteryMonitor.statusOut to safetyManager.batteryIn {
          @$::RoverA1::RoverProfile::RosTopic {
            msgType = "rover_msgs/BatteryStatus";
            qos = "Reliable";
            topic = "rover_battery/battery_status";
          }
        }
        connect twistMux.cmdOut to driveController.cmdIn {
          @$::RoverA1::RoverProfile::RosTopic {
            msgType = "geometry_msgs/TwistStamped";
            qos = "Reliable";
            topic = "cmd_vel";
          }
        }
        connect crsfTeleop.cmdOut to twistMux.rcIn {
          @$::RoverA1::RoverProfile::RosTopic {
            msgType = "geometry_msgs/TwistStamped";
            qos = "Reliable";
            topic = "teleop_elrs_cmd_vel_stamped";
          }
        }
        connect localization_imuIn to localization.imuIn;
        connect batteryMonitor_bmsIn to batteryMonitor.bmsIn;
        connect localization_fixIn to localization.fixIn;
        connect crsfTeleop_crsfIn to crsfTeleop.crsfIn;
        connect twistMux_navIn to twistMux.navIn;
        connect localization.odomOut to localization_odomOut;
        connect twistMux_webIn to twistMux.webIn;
      }
      part orchestrator {
        part navigation {
          attribute footprintRadius : $::ScalarValues::Real default := 0.693;
          attribute maxForwardSpeed : $::ScalarValues::Real default := 0.8;
          attribute maxReverseSpeed : $::ScalarValues::Real default := 0.5;
          in port scanIn: ~$::RoverA1::RoverA1Interfaces::LaserScan;
          in port odomIn: ~$::RoverA1::RoverA1Interfaces::Odometry;
          out port cmdOut: $::RoverA1::RoverA1Interfaces::TwistStamped;
        }
        in port navigation_scanIn: ~$::RoverA1::RoverA1Interfaces::LaserScan;
        in port navigation_odomIn: ~$::RoverA1::RoverA1Interfaces::Odometry;
        out port navigation_cmdOut: $::RoverA1::RoverA1Interfaces::TwistStamped;
        connect navigation_scanIn to navigation.scanIn;
        connect navigation_odomIn to navigation.odomIn;
        connect navigation.cmdOut to navigation_cmdOut;
      }
      part lidar {
        attribute scanRate : $::ScalarValues::Real default := 10;
        out port cloudOut: $::RoverA1::RoverA1Interfaces::PointCloud2;
      }
      part imu {
        out port imuOut: $::RoverA1::RoverA1Interfaces::Imu;
      }
      part gnss {
        attribute fixRate : $::ScalarValues::Real default := 1;
        out port fixOut: $::RoverA1::RoverA1Interfaces::NavSatFix;
      }
      part drive_4 {
        part wheel {
          attribute mass : $::ScalarValues::Real default := 2.5;
          attribute radius : $::ScalarValues::Real default := 0.1651;
          attribute width : $::ScalarValues::Real default := 0.108;
        }
        part motor {
          attribute currentLimit : $::ScalarValues::Real default := 15;
          attribute gearRatio : $::ScalarValues::Real default := 23.3;
          attribute gearboxEfficiency : $::ScalarValues::Real default := 0.70;
          attribute jointVelocityLimit : $::ScalarValues::Real default := 10.958;
          attribute noLoadSpeed : $::ScalarValues::Real default := 293.2;
        }
        part controller {
          in port wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
          in port powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        }
        in port controller_wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        in port controller_powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        connect controller_powerIn to controller.powerIn;
        connect controller_wheelCmdIn to controller.wheelCmdIn;
      }
      part drive_3 {
        part wheel {
          attribute mass : $::ScalarValues::Real default := 2.5;
          attribute radius : $::ScalarValues::Real default := 0.1651;
          attribute width : $::ScalarValues::Real default := 0.108;
        }
        part motor {
          attribute currentLimit : $::ScalarValues::Real default := 15;
          attribute gearRatio : $::ScalarValues::Real default := 23.3;
          attribute gearboxEfficiency : $::ScalarValues::Real default := 0.70;
          attribute jointVelocityLimit : $::ScalarValues::Real default := 10.958;
          attribute noLoadSpeed : $::ScalarValues::Real default := 293.2;
        }
        part controller {
          in port wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
          in port powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        }
        in port controller_wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        in port controller_powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        connect controller_wheelCmdIn to controller.wheelCmdIn;
        connect controller_powerIn to controller.powerIn;
      }
      part drive_2 {
        part wheel {
          attribute mass : $::ScalarValues::Real default := 2.5;
          attribute radius : $::ScalarValues::Real default := 0.1651;
          attribute width : $::ScalarValues::Real default := 0.108;
        }
        part motor {
          attribute currentLimit : $::ScalarValues::Real default := 15;
          attribute gearRatio : $::ScalarValues::Real default := 23.3;
          attribute gearboxEfficiency : $::ScalarValues::Real default := 0.70;
          attribute jointVelocityLimit : $::ScalarValues::Real default := 10.958;
          attribute noLoadSpeed : $::ScalarValues::Real default := 293.2;
        }
        part controller {
          in port wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
          in port powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        }
        in port controller_wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        in port controller_powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        connect controller_powerIn to controller.powerIn;
        connect controller_wheelCmdIn to controller.wheelCmdIn;
      }
      part drive_1 {
        part wheel {
          attribute mass : $::ScalarValues::Real default := 2.5;
          attribute radius : $::ScalarValues::Real default := 0.1651;
          attribute width : $::ScalarValues::Real default := 0.108;
        }
        part motor {
          attribute currentLimit : $::ScalarValues::Real default := 15;
          attribute gearRatio : $::ScalarValues::Real default := 23.3;
          attribute gearboxEfficiency : $::ScalarValues::Real default := 0.70;
          attribute jointVelocityLimit : $::ScalarValues::Real default := 10.958;
          attribute noLoadSpeed : $::ScalarValues::Real default := 293.2;
        }
        part controller {
          in port wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
          in port powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        }
        in port controller_wheelCmdIn: ~$::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        in port controller_powerIn: ~$::RoverA1::RoverA1Interfaces::ElectricPower;
        connect controller_wheelCmdIn to controller.wheelCmdIn;
        connect controller_powerIn to controller.powerIn;
      }
      part driveInterface {
        part driveUi {
          out port cmdOut: $::RoverA1::RoverA1Interfaces::TwistStamped;
          in port batteryIn: ~$::RoverA1::RoverA1Interfaces::BatteryStatus;
        }
        out port driveUi_cmdOut: $::RoverA1::RoverA1Interfaces::TwistStamped;
        in port driveUi_batteryIn: ~$::RoverA1::RoverA1Interfaces::BatteryStatus;
        connect driveUi_batteryIn to driveUi.batteryIn;
        connect driveUi.cmdOut to driveUi_cmdOut;
      }
      part compute {
        out port wheelCmdOut_4: $::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        out port wheelCmdOut_3: $::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        out port wheelCmdOut_2: $::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        out port wheelCmdOut_1: $::RoverA1::RoverA1Interfaces::WheelVelocityCommand;
        out port modbus: $::RoverA1::RoverA1Interfaces::ModbusFrame;
      }
      part battery {
        attribute capacity : $::ScalarValues::Real default := 40;
        attribute nominalVoltage : $::ScalarValues::Real default := 24;
        out port statusOut: $::RoverA1::RoverA1Interfaces::BatteryStatus;
        out port powerOut: $::RoverA1::RoverA1Interfaces::ElectricPower;
      }
      connect orchestrator.navigation_cmdOut to platform.twistMux_navIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "geometry_msgs/TwistStamped";
          qos = "Reliable";
          topic = "nav_cmd_vel_stamped";
        }
      }
      connect battery.powerOut to drive_4.controller_powerIn;
      connect platform.localization_odomOut to orchestrator.navigation_odomIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "nav_msgs/Odometry";
          qos = "Reliable";
          topic = "odometry/filtered";
        }
      }
      connect imu.imuOut to platform.localization_imuIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "sensor_msgs/Imu";
          qos = "SensorData";
          topic = "imu/data";
        }
      }
      connect compute.wheelCmdOut_4 to drive_4.controller_wheelCmdIn;
      connect battery.statusOut to platform.batteryMonitor_bmsIn;
      connect battery.powerOut to drive_1.controller_powerIn;
      connect driveInterface.driveUi_cmdOut to platform.twistMux_webIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "geometry_msgs/TwistStamped";
          qos = "Reliable";
          topic = "teleop_foxglove_cmd_vel_stamped";
        }
      }
      connect sensors.scanProjection_scanOut to orchestrator.navigation_scanIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "sensor_msgs/LaserScan";
          qos = "SensorData";
          topic = "scan";
        }
      }
      connect battery.powerOut to drive_3.controller_powerIn;
      connect battery.powerOut to drive_2.controller_powerIn;
      connect compute.modbus to safetyController.modbus;
      connect rc.crsfOut to platform.crsfTeleop_crsfIn;
      connect lidar.cloudOut to sensors.scanProjection_cloudIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "sensor_msgs/PointCloud2";
          qos = "SensorData";
          topic = "rslidar_points";
        }
      }
      connect compute.wheelCmdOut_3 to drive_3.controller_wheelCmdIn;
      connect compute.wheelCmdOut_1 to drive_1.controller_wheelCmdIn;
      connect gnss.fixOut to platform.localization_fixIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "sensor_msgs/NavSatFix";
          qos = "SensorData";
          topic = "gps/fix";
        }
      }
      connect platform.batteryMonitor_statusOut to driveInterface.driveUi_batteryIn {
        @$::RoverA1::RoverProfile::RosTopic {
          msgType = "rover_msgs/BatteryStatus";
          qos = "Reliable";
          topic = "rover_battery/battery_status";
        }
      }
      connect compute.wheelCmdOut_2 to drive_2.controller_wheelCmdIn;
    }
    package RoverA1Alloc {
      abstract allocation def RoverA1Alloc {
        end source: $::RoverA1::RoverA1Arch;
      }
      allocation def 'Scenario 1' specializes $::RoverA1::RoverA1Alloc::RoverA1Alloc {
        allocation 'Scenario 1#1' allocate source.platform to source.compute;
        allocation 'Scenario 1#2' allocate source.sensors to source.compute;
        allocation 'Scenario 1#3' allocate source.driveInterface to source.compute;
        allocation 'Scenario 1#4' allocate source.orchestrator to source.compute;
      }
    }
  }
