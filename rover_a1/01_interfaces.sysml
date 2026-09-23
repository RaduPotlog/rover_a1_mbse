/* Rover A1 — interface layer: messages (items), ports, ROS 2 topic metadata.
 * Mapping rule (rules/sysml_v2.md §ROS bridge): ROS msg -> item def,
 * publisher/subscriber endpoint -> port def (out/in item), topic -> flow + @RosTopic.
 */
package RoverA1_Interfaces {
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;

    doc /* Messages, ports and ROS 2 topic metadata shared by all Rover A1 packages. */

    // ---- ROS 2 topic metadata (applied to flows with @RosTopic) ----
    enum def QosProfile {
        enum SensorData;   // best-effort, volatile
        enum Reliable;     // reliable, volatile
        enum Latched;      // reliable, transient-local
    }
    metadata def RosTopic {
        doc /* Binds a SysML flow to a concrete ROS 2 topic (namespace 'rover'). */
        attribute topic : String;
        attribute msgType : String;
        attribute qos : QosProfile;
    }

    // ---- Messages (item defs) ----
    item def TwistStamped {
        attribute linearX : SpeedValue;
        attribute angularZ : AngularVelocityValue;
    }
    item def Odometry {
        attribute x : LengthValue;
        attribute y : LengthValue;
        attribute yaw : AngularMeasureValue;
    }
    item def LaserScan;
    item def PointCloud2;
    item def NavSatFix {
        attribute horizontalStd : LengthValue;
    }
    item def Imu;
    item def BatteryStatus {
        attribute stateOfCharge : Real;   // fraction 0.0–1.0
        attribute temperature : ThermodynamicTemperatureValue;
    }
    item def WheelVelocityCommand {
        attribute wheelSpeed : AngularVelocityValue;
    }
    item def ElectricPower;
    item def ModbusFrame;
    item def CrsfFrame;

    // ---- Ports ----
    port def TwistPort { out item cmd : TwistStamped; }
    port def OdometryPort { out item odom : Odometry; }
    port def LaserScanPort { out item scan : LaserScan; }
    port def PointCloudPort { out item cloud : PointCloud2; }
    port def NavSatFixPort { out item fix : NavSatFix; }
    port def ImuPort { out item imu : Imu; }
    port def BatteryStatusPort { out item status : BatteryStatus; }
    port def WheelCommandPort { out item wheelCmd : WheelVelocityCommand; }
    port def PowerPort {
        out item power : ElectricPower;
        attribute nominalVoltage : ElectricPotentialValue;
    }
    port def ModbusPort { inout item packet : ModbusFrame; }
    port def CrsfPort { out item packet : CrsfFrame; }
}
