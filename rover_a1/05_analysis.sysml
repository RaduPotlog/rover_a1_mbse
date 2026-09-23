/* Rover A1 — analysis and verification cases.
 * Numeric evaluation is done in MATLAB (skills/system_composer_sysml) or by hand;
 * the Pilot kernel checks structure and name resolution only.
 */
package RoverA1_Analysis {
    private import ISQ::*;
    private import SI::*;
    private import VerificationCases::*;
    private import RoverA1_Structure::*;
    private import RoverA1_Calculations::*;
    private import RoverA1_Requirements::*;

    analysis def EnduranceAnalysis {
        doc /* Estimate ideal runtime and check it against R-END-01.
             * Expected with baseline values: 40 Ah * 24 V / 160 W = 6.0 h (zero margin).
             * MATLAB R2026a Update 5, 2026-09-23 (mbse/matlab/analysis_rover_a1.m): calc 6.000 h,
             * Simulink EnduranceSim 6.000 h, margin +0.000 h -> PASS at zero margin (ideal model). */
        subject rover : RoverA1;
        objective enduranceObjective {
            doc /* Determine whether the rover meets its endurance requirement at average load. */
            require roverA1Specification.endurance;
        }
        return runtime : DurationValue =
            BatteryEndurance(rover.battery.capacity, rover.battery.nominalVoltage, rover.averageLoad);
    }

    analysis def SpeedMarginAnalysis {
        doc /* Rim-speed margin of the drivetrain vs the commanded max speed (R-PERF-01).
             * Expected: 10.958 rad/s * 0.1651 m = 1.809 m/s vs 1.2 m/s -> margin ~0.61 m/s.
             * MATLAB R2026a Update 5, 2026-09-23: 1.809 m/s, margin +0.609 m/s -> PASS. */
        subject rover : RoverA1;
        objective { require roverA1Specification.speedCapability; }
        return margin : SpeedValue =
            WheelRimSpeed(rover.drive#(1).motor.jointVelocityLimit, rover.drive#(1).wheel.radius)
            - rover.platform.driveController.maxLinearSpeed;
    }

    analysis enduranceAnalysis : EnduranceAnalysis { subject rover = roverA1; }
    analysis speedMarginAnalysis : SpeedMarginAnalysis { subject rover = roverA1; }

    verification def CommandTimeoutTest {
        doc /* Field test: stream cmd_vel, cut it, measure time until wheel velocity ~ 0
             * (rosbag of cmd_vel + odometry/wheels; see skill ros2_bag). */
        subject testRover : RoverA1;
        objective { verify roverA1Specification.cmdTimeout; }
        action collectData { out measuredStopDelay : DurationValue; }
        action evaluateData {
            in measuredStopDelay : DurationValue = collectData.measuredStopDelay;
            out verdict : VerdictKind = PassIf(measuredStopDelay <= 0.5 [s]);
        }
        return verdict : VerdictKind = evaluateData.verdict;
    }
    verification commandTimeoutTest : CommandTimeoutTest { subject testRover = roverA1; }

    verification def ConfigurationInspection {
        doc /* Verification by inspection: the deployed configuration values (cited in
             * RoverA1_Structure) satisfy the static limits. Re-run whenever the yaml changes.
             * Baseline result: PASS (0.8 <= 1.2 m/s; 100 >= 100 Hz; 323.15 <= 323.15 K; 0.2 <= 0.2 s).
             * Confirmed in MATLAB R2026a Update 5, 2026-09-23 from the System Composer parameters. */
        subject testRover : RoverA1;
        objective {
            verify roverA1Specification.navSpeed;
            verify roverA1Specification.controlRate;
            verify roverA1Specification.batteryOverTemp;
            verify roverA1Specification.watchdog;
        }
        return verdict : VerdictKind = PassIf(
            testRover.orchestrator.navigation.maxForwardSpeed <= testRover.platform.driveController.maxLinearSpeed and
            testRover.platform.driveController.updateRate >= 100 [Hz] and
            testRover.platform.safetyManager.batteryEstopTemperature <= 323.15 [K] and
            testRover.safetyController.watchdogPeriod <= 0.2 [s]);
    }
    verification configurationInspection : ConfigurationInspection { subject testRover = roverA1; }
}
