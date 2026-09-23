/* Rover A1 — reusable calculations (pure functions; no model navigation). */
package RoverA1_Calculations {
    private import ISQ::*;
    private import SI::*;

    calc def BatteryEndurance {
        doc /* Ideal runtime = stored energy / average electrical load (no derating). */
        in capacity : ElectricChargeValue;
        in voltage : ElectricPotentialValue;
        in load : PowerValue;
        return runtime : DurationValue = capacity * voltage / load;
    }
    calc def WheelRimSpeed {
        doc /* Linear rim speed of a wheel from its joint angular speed. */
        in omega : AngularVelocityValue;
        in radius : LengthValue;
        return rimSpeed : SpeedValue = omega * radius;
    }
}
