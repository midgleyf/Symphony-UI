% Wrapper script (NOT a function) to load the Symphony .NET assemblies correctly.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

if verLessThan('matlab', '7.12')
    error('Symphony requires MATLAB 7.12.0 (R2011a) or later');
end

% Add base directories to the path.
symphonyPath = mfilename('fullpath');
parentDir = fileparts(symphonyPath);
addpath(fullfile(parentDir, 'Utility'));
addpath(fullfile(parentDir, 'StimGL'));

% Load the Symphony .NET framework
addSymphonyFramework();

% Launch the user interface
global symphonyInstance;

if isempty(symphonyInstance)
    % Run the built-in configuration script.
    run('SymphonyConfiguration');
    
    % Run the user specific configuration script.
    up = userpath;
    up = regexprep(up, ';', ''); % Remove semicolon at end of userpath
    if exist(fullfile(up, 'SymphonyConfiguration.m'), 'file')
        run(fullfile(up, 'SymphonyConfiguration'));
    end
    
    symphonyInstance = Symphony(rigConfigsDir, protocolsDir, figureHandlersDir, sourcesFile);
else
    symphonyInstance.showMainWindow();
end

% Clean up
clear symphonyPath parentDir configFile rigConfigsDir protocolsDir figureHandlersDir sourcesFile up var