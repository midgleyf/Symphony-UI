% Place a copy of this script in the MATLAB user path. Edit the copied script to define a user specific Symphony configuration.
% Run the userpath command at the MATLAB command line to determine the user path directory.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

% Directory containing rig configurations.
% Rig configuration .m files must be at the top level of this directory.
rigConfigsDir = fullfile(fileparts(mfilename('fullpath')), 'Example Rig Configurations');

% Directory containing protocols.
% Each protocol .m file must be contained within a directory of the same name as the protocol class itself.
protocolsDir = fullfile(fileparts(mfilename('fullpath')), 'Example Protocols');

% Directory containing figure handlers (built-in figure handlers are always available).
% Figure handler .m files must be at the top level of this directory.
figureHandlersDir = '';

% Text file specifying the source hierarchy.
sourcesFile = fullfile(fileparts(mfilename('fullpath')), 'ExampleSourceHierarchy.txt');