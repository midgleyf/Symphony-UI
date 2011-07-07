% Wrapper script (NOT a function) to load the Symphony .NET assemblies correctly.

            
% Add our utility and figure handler folders to the search path.
symphonyPath = mfilename('fullpath');
parentDir = fileparts(symphonyPath);
addpath(fullfile(parentDir, filesep, 'Utility'));
addpath(fullfile(parentDir, filesep, 'Figure Handlers'));
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
