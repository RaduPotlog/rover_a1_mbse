/* Rover A1 — physical + software structure.
 * Values come from rover_description / rover_controller / rover_navigation configs;
 * each value cites its source. Unknowns are marked TBD in doc comments, never invented.
 */
package RoverA1_Structure {
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import RoverA1_Interfaces::*;

    // =========================== Hardware ===========================
    part def Wheel {
        doc /* 13-inch wheel. Source: rover_description/config/wheel_01.yaml */
        attribute radius : LengthValue = 0.1651 [m];
        attribute width : LengthValue = 0.108 [m];
        attribute mass : MassValue = 2.5 [kg];
    }
    part def DriveMotor {
        doc /* 24 V brushed DC, 2800 rpm no-load (= 293.2 rad/s), gearbox 23.3:1, eta 0.70,
             * 1024-count encoder. Source: urdf/common/wheel.urdf.xacro, rover_hardware_interface/README.md */
        attribute noLoadSpeed : AngularVelocityValue = 293.2 [rad/s];
        attribute gearRatio : Real = 23.3;
        attribute gearboxEfficiency : Real = 0.70;
        attribute currentLimit : ElectricCurrentValue = 15 [A];
        attribute jointVelocityLimit : AngularVelocityValue = 10.958 [rad/s];
    }
    part def MotorController {
        doc /* Phidget DCC1000, one per wheel. */
        port wheelCmdIn : ~WheelCommandPort;
        port powerIn : ~PowerPort;
    }
    part def DriveModule {
        doc /* One wheel + motor + controller; four per rover (skid-steer, 2 per side). */
        part wheel : Wheel;
        part motor : DriveMotor;
        part controller : MotorController;
    }
    part def Battery {
        doc /* 40 Ah design capacity ("BAT01"), Daly BMS read over BLE by an ESP32, UDP :4444.
             * TBD: chemistry and nominal pack voltage are not documented; 24 V is the
             * motor-supply parameter and is used here as an ASSUMPTION.
             * Source: rover_battery/config/rover_battery.yaml, rover_description/config/battery.yaml */
        attribute capacity : ElectricChargeValue = 40 [A*h];
        attribute nominalVoltage : ElectricPotentialValue = 24 [V];
        port powerOut : PowerPort;
        port statusOut : BatteryStatusPort;
    }
    part def SafetyController {
        doc /* Hardware E-stop + GPIO over Modbus TCP 192.168.88.11:502, 200 ms watchdog.
             * Source: src/rover_ros/rover_description/urdf/rover_a1/rover_a1_macro.urdf.xacro */
        attribute watchdogPeriod : DurationValue = 0.2 [s];
        port modbus : ModbusPort;
    }
    part def ComputeUnit {
        doc /* ARM64 board running balenaOS. TBD: exact board not documented. */
        port modbus : ModbusPort;
        port wheelCmdOut[4] : WheelCommandPort;
    }
    part def Lidar {
        doc /* RoboSense RS16, UDP 6699/7788, ~10 Hz. Source: src/rover_sensors/rover_rs16_lidar/README.md */
        attribute scanRate : FrequencyValue = 10 [Hz];
        port cloudOut : PointCloudPort;
    }
    part def ImuSensor {
        doc /* Phidgets Spatial MOT0110 + Madgwick filter. */
        port imuOut : ImuPort;
    }
    part def GnssRouter {
        doc /* Teltonika RUTX11, NMEA over UDP 10110, 1 Hz GGA, no RTK. Source: src/rover_sensors/rover_gps/README.md */
        attribute fixRate : FrequencyValue = 1 [Hz];
        port fixOut : NavSatFixPort;
    }
    part def RcReceiver {
        doc /* ExpressLRS / CRSF over UART 460800 baud. */
        port crsfOut : CrsfPort;
    }

    // =========================== Software ===========================
    // One part def per ROS 2 package / node group. Allocated to hardware below.
    part def TwistMux {
        doc /* Priorities web UI 100 > RC 10 > Nav2 5; motion_lock 200.
             * Source: src/rover_ros/rover_twist_mux/config/rover_twist_mux.yaml */
        attribute inputTimeout : DurationValue = 0.5 [s];
        port webIn : ~TwistPort;
        port rcIn : ~TwistPort;
        port navIn : ~TwistPort;
        port cmdOut : TwistPort;
    }
    part def DriveController {
        doc /* diff_drive_controller + per-wheel SeededPidController, 100 Hz.
             * Source: src/rover_ros/rover_controller/config/wheel_01_controller.yaml */
        attribute updateRate : FrequencyValue = 100 [Hz];
        attribute maxLinearSpeed : SpeedValue = 1.2 [m/s];
        attribute maxLinearAccel : AccelerationValue = 2.7 [m/s^2];
        attribute maxAngularSpeed : AngularVelocityValue = 1.0 [rad/s];
        attribute cmdTimeout : DurationValue = 0.5 [s];
        port cmdIn : ~TwistPort;
        port odomOut : OdometryPort;
    }
    part def Localization {
        doc /* rover_localization: robot_localization EKF 50 Hz (+ navsat), rover_gps_heading. */
        attribute ekfRate : FrequencyValue = 50 [Hz];
        port wheelOdomIn : ~OdometryPort;
        port imuIn : ~ImuPort;
        port fixIn : ~NavSatFixPort;
        port odomOut : OdometryPort;
    }
    part def Navigation {
        doc /* Nav2 (MPPI 10 Hz, Smac 2D 1 Hz), velocity smoother, footprint.
             * Source: src/rover_orchestrator/rover_navigation/config/rover_nav_params.yaml */
        attribute maxForwardSpeed : SpeedValue = 0.8 [m/s];
        attribute maxReverseSpeed : SpeedValue = 0.5 [m/s];
        attribute footprintRadius : LengthValue = 0.693 [m];
        port odomIn : ~OdometryPort;
        port scanIn : ~LaserScanPort;
        port cmdOut : TwistPort;
    }
    part def ScanProjection {
        doc /* rover_rs16_lidar: PointCloud2 -> LaserScan projection. */
        port cloudIn : ~PointCloudPort;
        port scanOut : LaserScanPort;
    }
    part def CrsfTeleop {
        doc /* rover_crsf_teleop */
        port crsfIn : ~CrsfPort;
        port cmdOut : TwistPort;
    }
    part def DriveUi {
        doc /* rover_drive_interface web UI via foxglove_bridge (nginx :5000). */
        port cmdOut : TwistPort;
        port batteryIn : ~BatteryStatusPort;
    }
    part def SafetyManager {
        doc /* BT safety manager, 10 Hz; E-stop at battery > 50 degC, shutdown > 60 degC.
             * Source: src/rover_ros/rover_safety/config/rover_safety.yaml */
        attribute batteryEstopTemperature : ThermodynamicTemperatureValue = 323.15 [K];
        attribute batteryShutdownTemperature : ThermodynamicTemperatureValue = 333.15 [K];
        port batteryIn : ~BatteryStatusPort;
        port modbus : ModbusPort;
    }
    part def BatteryMonitor {
        doc /* rover_battery: decodes BMS UDP frames. */
        port bmsIn : ~BatteryStatusPort;
        port statusOut : BatteryStatusPort;
    }

    // Container boundary = balena service (rover_docker/docker-compose.yml).
    part def PlatformService {
        part twistMux : TwistMux;
        part driveController : DriveController;
        part localization : Localization;
        part crsfTeleop : CrsfTeleop;
        part safetyManager : SafetyManager;
        part batteryMonitor : BatteryMonitor;
    }
    part def OrchestratorService { part navigation : Navigation; }
    part def SensorsService { part scanProjection : ScanProjection; }
    part def DriveInterfaceService { part driveUi : DriveUi; }

    // =========================== System ===========================
    part def RoverA1 {
        doc /* 4-wheel skid-steer rover, ROS 2 Lyrical over rmw_zenoh. Body 0.702 x 0.626 x 0.256 m.
             * Source: bodyMass/size src/rover_ros/rover_description/urdf/rover_a1/base.urdf.xacro;
             * wheelSeparation/wheelbase src/rover_ros/rover_description/config/wheel_01.yaml */
        attribute bodyMass : MassValue = 33.45 [kg];
        attribute wheelSeparation : LengthValue = 0.62602 [m];
        attribute wheelbase : LengthValue = 0.5084 [m];
        attribute averageLoad : PowerValue = 160 [W];   // simulation assumption, battery.yaml

        // --- hardware ---
        part drive[4] : DriveModule;
        part battery : Battery;
        part safetyController : SafetyController;
        part compute : ComputeUnit;
        part lidar : Lidar;
        part imu : ImuSensor;
        part gnss : GnssRouter;
        part rc : RcReceiver;

        attribute totalMass : MassValue = bodyMass + 4 * drive#(1).wheel.mass;

        // --- software (balena services) ---
        part platform : PlatformService;
        part orchestrator : OrchestratorService;
        part sensors : SensorsService;
        part driveInterface : DriveInterfaceService;

        // --- command chain: UI / RC / Nav2 -> twist_mux -> drive controller ---
        flow of TwistStamped from driveInterface.driveUi.cmdOut.cmd to platform.twistMux.webIn.cmd {
            @RosTopic { topic = "teleop_foxglove_cmd_vel_stamped"; msgType = "geometry_msgs/TwistStamped"; qos = QosProfile::Reliable; }
        }
        flow of TwistStamped from platform.crsfTeleop.cmdOut.cmd to platform.twistMux.rcIn.cmd {
            @RosTopic { topic = "teleop_elrs_cmd_vel_stamped"; msgType = "geometry_msgs/TwistStamped"; qos = QosProfile::Reliable; }
        }
        flow of TwistStamped from orchestrator.navigation.cmdOut.cmd to platform.twistMux.navIn.cmd {
            @RosTopic { topic = "nav_cmd_vel_stamped"; msgType = "geometry_msgs/TwistStamped"; qos = QosProfile::Reliable; }
        }
        flow of TwistStamped from platform.twistMux.cmdOut.cmd to platform.driveController.cmdIn.cmd {
            @RosTopic { topic = "cmd_vel"; msgType = "geometry_msgs/TwistStamped"; qos = QosProfile::Reliable; }
        }

        // --- state estimation ---
        flow of Odometry from platform.driveController.odomOut.odom to platform.localization.wheelOdomIn.odom {
            @RosTopic { topic = "odometry/wheels"; msgType = "nav_msgs/Odometry"; qos = QosProfile::Reliable; }
        }
        flow of Imu from imu.imuOut.imu to platform.localization.imuIn.imu {
            @RosTopic { topic = "imu/data"; msgType = "sensor_msgs/Imu"; qos = QosProfile::SensorData; }
        }
        flow of NavSatFix from gnss.fixOut.fix to platform.localization.fixIn.fix {
            @RosTopic { topic = "gps/fix"; msgType = "sensor_msgs/NavSatFix"; qos = QosProfile::SensorData; }
        }
        flow of Odometry from platform.localization.odomOut.odom to orchestrator.navigation.odomIn.odom {
            @RosTopic { topic = "odometry/filtered"; msgType = "nav_msgs/Odometry"; qos = QosProfile::Reliable; }
        }

        // --- perception ---
        flow of PointCloud2 from lidar.cloudOut.cloud to sensors.scanProjection.cloudIn.cloud {
            @RosTopic { topic = "rslidar_points"; msgType = "sensor_msgs/PointCloud2"; qos = QosProfile::SensorData; }
        }
        flow of LaserScan from sensors.scanProjection.scanOut.scan to orchestrator.navigation.scanIn.scan {
            @RosTopic { topic = "scan"; msgType = "sensor_msgs/LaserScan"; qos = QosProfile::SensorData; }
        }

        // --- power + actuation (ros2_control writes wheel velocity via the Phidget controllers) ---
        flow of ElectricPower from battery.powerOut.power to drive.controller.powerIn.power;
        flow of WheelVelocityCommand from compute.wheelCmdOut.wheelCmd to drive.controller.wheelCmdIn.wheelCmd;

        // --- energy / safety ---
        flow of CrsfFrame from rc.crsfOut.packet to platform.crsfTeleop.crsfIn.packet;
        flow of BatteryStatus from battery.statusOut.status to platform.batteryMonitor.bmsIn.status;
        flow of BatteryStatus from platform.batteryMonitor.statusOut.status to platform.safetyManager.batteryIn.status {
            @RosTopic { topic = "rover_battery/battery_status"; msgType = "rover_msgs/BatteryStatus"; qos = QosProfile::Reliable; }
        }
        flow of BatteryStatus from platform.batteryMonitor.statusOut.status to driveInterface.driveUi.batteryIn.status {
            @RosTopic { topic = "rover_battery/battery_status"; msgType = "rover_msgs/BatteryStatus"; qos = QosProfile::Reliable; }
        }
        interface : ModbusLink connect compute.modbus to safetyController.modbus;
    }

    part roverA1 : RoverA1;   // the as-built configuration

    interface def ModbusLink {
        doc /* Modbus TCP, 200 ms watchdog kick. */
        end master : ModbusPort;
        end slave : ModbusPort;
    }

    // --- software -> hardware allocation (balena services -> ARM64 compute) ---
    allocation def SoftwareToCompute {
        end software : Parts::Part;
        end hardware : ComputeUnit;
    }
    allocation platformAlloc : SoftwareToCompute allocate roverA1.platform to roverA1.compute;
    allocation sensorsAlloc : SoftwareToCompute allocate roverA1.sensors to roverA1.compute;
    allocation uiAlloc : SoftwareToCompute allocate roverA1.driveInterface to roverA1.compute;
    allocation navAlloc : SoftwareToCompute allocate roverA1.orchestrator to roverA1.compute {
        doc /* Nav2 may instead run on a companion computer over Zenoh — deployment-dependent. */
    }
}
