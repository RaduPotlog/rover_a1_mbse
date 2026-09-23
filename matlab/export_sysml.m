function export_sysml()
%EXPORT_SYSML Pipeline B (.claude/rules/matlab_simulink_mbse.md §4B):
%   wrap the generated artifacts in a MATLAB project and export it to
%   SysML v2 text with systemcomposer.sysml.exportFromMLProject (R2026a+).
%   Output: ../export/rover_a1_export.sysml — validate with /sysml-validate
%   and diff against the hand-written model; never overwrite mbse/rover_a1.
here = fileparts(mfilename('fullpath'));
prjFile = fullfile(here, "RoverA1.prj");
if isfile(prjFile)
    proj = openProject(prjFile);
else
    proj = matlab.project.createProject(Folder=here, Name="RoverA1");
end
for f = ["arch/RoverA1Arch.slx", "arch/RoverA1Interfaces.sldd", "arch/RoverProfile.xml", ...
         "arch/RoverA1Alloc.mldatx", "arch/EnduranceSim.slx", ...
         "build_architecture.m", "build_endurance_sim.m", "analysis_rover_a1.m", "export_sysml.m"]
    p = fullfile(here, f);
    if isfile(p) && isempty(findFile(proj, p)), addFile(proj, p); end
end
if ~any(strcmp([proj.ProjectPath.File], fullfile(here, "arch")))
    addPath(proj, fullfile(here, "arch"));
end
outDir = fullfile(here, "..", "export");
if ~isfolder(outDir), mkdir(outDir); end
out = fullfile(outDir, "rover_a1_export.sysml");
systemcomposer.sysml.exportFromMLProject(fullfile(proj.RootFolder, proj.Name + ".prj"), out);
close(proj);
fprintf("Exported %s\n", out);
end
