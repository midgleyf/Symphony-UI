% Wrapper script (NOT a function) to load the Symphony .NET assemblies correctly.

if verLessThan('matlab', '7.12')
    error('Symphony requires MATLAB 7.12.0 (R2011a) or later');
end

% Add our utility and figure handler folders to the search path.
symphonyPath = mfilename('fullpath');
parentDir = fileparts(symphonyPath);
addpath(fullfile(parentDir, 'Utility'));
addpath(fullfile(parentDir, 'Rig Configurations'));
addpath(fullfile(parentDir, 'Figure Handlers'));
addpath(fullfile(parentDir, 'StimGL'));
clear symphonyPath parentDir

% Load the Symphony .NET framework
addSymphonyFramework();

% Launch the user interface
global symphonyInstance;

if isempty(symphonyInstance)
    symphonyInstance = Symphony();
else
    symphonyInstance.showMainWindow();
end
