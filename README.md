# Rover A1 — SysML v2 system model

A SysML v2 text model of Rover A1: structure, ROS 2 interfaces, baseline
requirements, calculations, and analysis and verification cases. Every value
cites the workspace file it came from.

| File | Package | Contents |
|------|---------|----------|
| `rover_a1/01_interfaces.sysml` | `RoverA1_Interfaces` | message `item def`s, `port def`s, `RosTopic` metadata, `QosProfile` |
| `rover_a1/02_structure.sysml` | `RoverA1_Structure` | hardware + software parts, balena services, topic flows, Modbus link, SW→HW allocation |
| `rover_a1/03_calculations.sysml` | `RoverA1_Calculations` | `BatteryEndurance`, `WheelRimSpeed` |
| `rover_a1/04_requirements.sysml` | `RoverA1_Requirements` | R-PERF-01/02, R-CTRL-01, R-SAF-01/02/03, R-END-01 (BASELINE), `satisfy` |
| `rover_a1/05_analysis.sysml` | `RoverA1_Analysis` | endurance + speed-margin analyses; command-timeout test + configuration-inspection verification (every requirement is analysed or verified) |
| `diagrams/` | — | rendered SVGs (`--viz`) |
| `matlab/build_architecture.m` | — | **generated** from SysML (`sysml_to_syscomp.py`) → `matlab/arch/RoverA1Arch.slx`, `RoverA1Interfaces.sldd`, `RoverProfile.xml`, `RoverA1Alloc.mldatx` |
| `matlab/analysis_rover_a1.m` | — | evaluates the SysML analyses/verifications from the architecture parameters + Simulink twin `EnduranceSim.slx` → `matlab/results/analysis_results.json` |
| `matlab/export_sysml.m` | — | MATLAB project `RoverA1.prj` → `export/rover_a1_export.sysml` (lossy, for diffs) |

```bash
# validate + render (see .claude/skills/sysml_v2_modeling/SKILL.md)
~/mbse_ws/tools/sysml-env/bin/python ../.claude/skills/sysml_v2_modeling/scripts/sysml_validate.py rover_a1 \
  --viz RoverA1_Structure::RoverA1@interconnection --out diagrams
```

Round trip (MATLAB R2026a via the `matlab` MCP server — see `.claude/skills/system_composer_sysml/SKILL.md`):
SysML → `/sysml-validate` → generate → `build_architecture` → `analysis_rover_a1` → results back into `05_analysis` docs.
Latest run 2026-09-23: all requirements PASS; R-END-01 at **zero margin** (6.000 h calc = 6.000 h Simulink).

## Setup on a new machine

This repo is cloned as `mbse/` inside the workspace root, next to `.claude/`
(from `github.com/RaduPotlog/.claude`):
```bash
cd ~/ros2_ws/rover_a1
git clone https://github.com/RaduPotlog/rover_a1_mbse.git mbse
git clone https://github.com/RaduPotlog/.claude.git .claude
ln -s mbse/.mcp.json .mcp.json        # Claude Code reads .mcp.json from the workspace root
```
`.mcp.json` registers the `matlab` MCP server; it holds Windows paths
(`C:\Users\potlo\...`), so adjust them for another machine. The tools outside
git (SysML Pilot kernel in `~/mbse_ws`, MATLAB R2026a, MATLAB MCP server,
Simulink Agentic Toolkit, `startup.m`) are described in
`.claude/rules/matlab_simulink_mbse.md` §3 and
`.claude/skills/sysml_v2_modeling/SKILL.md` (Toolchain).

Open items (`TBD` in the model):
- Battery chemistry and nominal pack voltage (24 V is assumed from the motor supply).
- The compute board model.
- The endurance target: 6 h at 160 W is a simulation assumption, and at the
  assumed values the endurance analysis has zero margin.
- Payload and measured total mass (the URDF CAD value is about 43.4 kg).
