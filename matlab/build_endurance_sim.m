function build_endurance_sim()
%BUILD_ENDURANCE_SIM Create EnduranceSim.slx, the Simulink twin of SysML
%   RoverA1_Analysis::EnduranceAnalysis (R-END-01).
%
%   Integrates the charge drawn from the pack under an electrical load profile
%   and stops when the usable capacity is used up. The stop time is the runtime.
%
%   Inputs (model workspace / SimulationInput variables):
%     loadProfile  timeseries [W]  (default: constant averageLoad)
%     V_nom        pack voltage [V]
%     capacity_Ah  usable capacity [A*h]
%
%   Ideal model (no voltage sag, no derating) — same assumptions as the SysML
%   calc BatteryEndurance. Replace loadProfile with a measured profile
%   (rosbag of rover_battery/battery_status: V*I) for a realistic estimate.
here = fileparts(mfilename('fullpath'));
mdl = "EnduranceSim";
file = fullfile(here, "arch", mdl + ".slx");
if bdIsLoaded(mdl), close_system(mdl, 0); end
if isfile(file), delete(file); end

new_system(mdl);
add_block("simulink/Sources/From Workspace", mdl + "/Load_W", ...
    VariableName="loadProfile", Interpolate="on", OutputAfterFinalValue="Holding final value", ...
    Position=[40 90 140 120]);
add_block("simulink/Math Operations/Gain", mdl + "/Current_A", Gain="1/V_nom", Position=[190 90 250 120]);
add_block("simulink/Continuous/Integrator", mdl + "/Charge_As", Position=[300 90 340 120]);
add_block("simulink/Math Operations/Gain", mdl + "/To_Ah", Gain="1/3600", Position=[390 90 450 120]);
add_block("simulink/Logic and Bit Operations/Compare To Constant", mdl + "/Depleted", ...
    relop=">=", const="capacity_Ah", ZeroCross="on", Position=[510 90 580 120]);
add_block("simulink/Sinks/Stop Simulation", mdl + "/Stop", Position=[630 90 670 120]);
add_block("simulink/Sinks/To Workspace", mdl + "/drawn_Ah", VariableName="drawn_Ah", ...
    SaveFormat="Timeseries", Position=[510 160 580 190]);

add_line(mdl, "Load_W/1", "Current_A/1");
add_line(mdl, "Current_A/1", "Charge_As/1");
add_line(mdl, "Charge_As/1", "To_Ah/1");
add_line(mdl, "To_Ah/1", "Depleted/1");
add_line(mdl, "Depleted/1", "Stop/1");
add_line(mdl, "To_Ah/1", "drawn_Ah/1", autorouting="on");

set_param(mdl, StopTime="1e6", Solver="VariableStepAuto", MaxStep="10", ...
    ReturnWorkspaceOutputs="on");
Simulink.BlockDiagram.arrangeSystem(mdl);
save_system(mdl, file);
close_system(mdl, 0);
fprintf("Built %s\n", file);
end
