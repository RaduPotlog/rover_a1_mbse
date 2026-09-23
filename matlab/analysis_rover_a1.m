function R = analysis_rover_a1()
%ANALYSIS_ROVER_A1 Evaluate the SysML v2 analysis/verification cases of
%   mbse/rover_a1/05_analysis.sysml numerically (Pipeline C,
%   .claude/rules/matlab_simulink_mbse.md §4C).
%
%   All inputs are read from the System Composer model built from the SysML
%   source (arch/RoverA1Arch.slx, component parameters), so the numbers
%   follow the model; nothing is duplicated here.
%   Results: printed + arch/../results/analysis_results.json.
here = fileparts(mfilename('fullpath'));
m = systemcomposer.loadModel(fullfile(here, "arch", "RoverA1Arch"));
P = @(path, name) pget(m, path, name);

% ---- EnduranceAnalysis (R-END-01): BatteryEndurance calc -------------------
cap = P("battery", "capacity");          % A*h
V   = P("battery", "nominalVoltage");    % V   (ASSUMPTION in SysML)
Pl  = P("", "averageLoad");              % W   (simulation assumption)
R.endurance.calc_h = cap * V / Pl;
R.endurance.required_h = 6;
R.endurance.margin_h = R.endurance.calc_h - R.endurance.required_h;

% Simulink twin (constant load = averageLoad)
simFile = fullfile(here, "arch", "EnduranceSim.slx");
if ~isfile(simFile), build_endurance_sim(); end
load_system(simFile);
in = Simulink.SimulationInput("EnduranceSim");
in = in.setVariable("loadProfile", timeseries([Pl; Pl], [0; 1]));
in = in.setVariable("V_nom", V);
in = in.setVariable("capacity_Ah", cap);
out = sim(in);
R.endurance.sim_h = out.tout(end) / 3600;
close_system("EnduranceSim", 0);
R.endurance.pass = R.endurance.calc_h >= R.endurance.required_h;

% ---- SpeedMarginAnalysis (R-PERF-01): WheelRimSpeed calc -------------------
omega = P("drive_1/motor", "jointVelocityLimit");   % rad/s
r     = P("drive_1/wheel", "radius");               % m
vmax  = P("platform/driveController", "maxLinearSpeed");
R.speed.rim_mps = omega * r;
R.speed.commanded_mps = vmax;
R.speed.margin_mps = R.speed.rim_mps - vmax;
R.speed.pass = R.speed.margin_mps >= 0;

% ---- ConfigurationInspection (R-PERF-02, R-CTRL-01, R-SAF-02, R-SAF-03) -----
R.inspection.navSpeed    = P("orchestrator/navigation", "maxForwardSpeed") <= vmax;
R.inspection.controlRate = P("platform/driveController", "updateRate") >= 100;
R.inspection.overTemp    = P("platform/safetyManager", "batteryEstopTemperature") <= 323.15;
R.inspection.watchdog    = P("safetyController", "watchdogPeriod") <= 0.2;
R.inspection.pass = all(struct2array(rmfield(R.inspection, {})));

% ---- CommandTimeoutTest (R-SAF-01) is a field test — model check only ------
R.cmdTimeout.config_pass = P("platform/driveController", "cmdTimeout") <= 0.5 && ...
    P("platform/twistMux", "inputTimeout") <= 0.5;

R.meta.matlab = version; R.meta.date = string(datetime("now", Format="yyyy-MM-dd HH:mm"));
fprintf("R-END-01  endurance  calc %.3f h | Simulink %.3f h | required %.1f h | margin %+.3f h -> %s\n", ...
    R.endurance.calc_h, R.endurance.sim_h, R.endurance.required_h, R.endurance.margin_h, verdict(R.endurance.pass));
fprintf("R-PERF-01 rim speed  %.3f m/s vs commanded %.2f m/s | margin %+.3f m/s -> %s\n", ...
    R.speed.rim_mps, vmax, R.speed.margin_mps, verdict(R.speed.pass));
fprintf("Inspection R-PERF-02 %s | R-CTRL-01 %s | R-SAF-02 %s | R-SAF-03 %s\n", ...
    verdict(R.inspection.navSpeed), verdict(R.inspection.controlRate), ...
    verdict(R.inspection.overTemp), verdict(R.inspection.watchdog));
fprintf("R-SAF-01  cmd timeout config %s (field test still required)\n", verdict(R.cmdTimeout.config_pass));

resDir = fullfile(here, "results");
if ~isfolder(resDir), mkdir(resDir); end
writelines(jsonencode(R, PrettyPrint=true), fullfile(resDir, "analysis_results.json"));
end

function v = pget(m, path, name)
if path == ""
    arch = m.Architecture;
else
    arch = lookup(m, Path="RoverA1Arch/" + path).Architecture;
end
p = arch.getParameter(name);
v = str2double(p.Value);
assert(~isnan(v), "parameter %s/%s is not numeric", path, name);
end

function s = verdict(ok)
if ok, s = "PASS"; else, s = "FAIL"; end
end
