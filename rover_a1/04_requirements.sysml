/* Rover A1 — baseline requirements.
 * Status: BASELINE — values are derived from the current configuration
 * (rover_controller, rover_navigation, rover_safety, battery.yaml) and still
 * need confirmation by the system owner. They are not externally sourced specs.
 */
package RoverA1_Requirements {
    private import ISQ::*;
    private import SI::*;
    private import RoverA1_Structure::*;
    private import RoverA1_Calculations::*;

    // ---------------- Performance ----------------
    requirement def <'R-PERF-01'> SpeedCapability {
        doc /* The drivetrain shall be able to reach the maximum linear speed the drive controller may command. */
        subject rover : RoverA1;
        attribute achievable : SpeedValue =
            WheelRimSpeed(rover.drive#(1).motor.jointVelocityLimit, rover.drive#(1).wheel.radius);
        require constraint { achievable >= rover.platform.driveController.maxLinearSpeed }
    }
    requirement def <'R-PERF-02'> NavigationSpeedWithinDriveLimit {
        doc /* Nav2 shall never request more forward speed than the drive controller accepts. */
        subject rover : RoverA1;
        require constraint {
            rover.orchestrator.navigation.maxForwardSpeed <= rover.platform.driveController.maxLinearSpeed
        }
    }
    requirement def <'R-CTRL-01'> ControlLoopRate {
        doc /* The wheel control loop shall run at 100 Hz or faster. */
        subject rover : RoverA1;
        attribute minRate : FrequencyValue = 100 [Hz];
        require constraint { rover.platform.driveController.updateRate >= minRate }
    }

    // ---------------- Safety ----------------
    requirement def <'R-SAF-01'> CommandTimeout {
        doc /* The rover shall stop driving within 0.5 s after its velocity command stream stops. */
        subject rover : RoverA1;
        attribute maxTimeout : DurationValue = 0.5 [s];
        require constraint {
            rover.platform.driveController.cmdTimeout <= maxTimeout and
            rover.platform.twistMux.inputTimeout <= maxTimeout
        }
    }
    requirement def <'R-SAF-02'> BatteryOverTemperatureStop {
        doc /* The rover shall trigger an E-stop at or before a battery temperature of 50 degC (323.15 K). */
        subject rover : RoverA1;
        attribute maxEstopTemperature : ThermodynamicTemperatureValue = 323.15 [K];
        require constraint { rover.platform.safetyManager.batteryEstopTemperature <= maxEstopTemperature }
    }
    requirement def <'R-SAF-03'> SafetyWatchdog {
        doc /* The hardware safety controller watchdog period shall not exceed 200 ms. */
        subject rover : RoverA1;
        attribute maxPeriod : DurationValue = 0.2 [s];
        require constraint { rover.safetyController.watchdogPeriod <= maxPeriod }
    }

    // ---------------- Endurance ----------------
    requirement def <'R-END-01'> Endurance {
        doc /* The rover shall operate for at least 6 h at its average electrical load.
             * TBD: 6 h and 160 W are simulation assumptions from battery.yaml; pack voltage is assumed 24 V. */
        subject rover : RoverA1;
        attribute minRuntime : DurationValue = 6 [h];
        attribute runtime : DurationValue =
            BatteryEndurance(rover.battery.capacity, rover.battery.nominalVoltage, rover.averageLoad);
        require constraint { runtime >= minRuntime }
    }

    // ---------------- Specification group ----------------
    requirement roverA1Specification {
        doc /* Rover A1 baseline system specification. */
        subject vehicle : RoverA1;
        requirement speedCapability : SpeedCapability { subject = vehicle; }
        requirement navSpeed : NavigationSpeedWithinDriveLimit { subject = vehicle; }
        requirement controlRate : ControlLoopRate { subject = vehicle; }
        requirement cmdTimeout : CommandTimeout { subject = vehicle; }
        requirement batteryOverTemp : BatteryOverTemperatureStop { subject = vehicle; }
        requirement watchdog : SafetyWatchdog { subject = vehicle; }
        requirement endurance : Endurance { subject = vehicle; }
    }

    satisfy roverA1Specification by roverA1;
}
