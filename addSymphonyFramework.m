%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function addSymphonyFramework()
    if isempty(which('NET.convertArray'))
        % Use the .NET stub classes instead of the real thing on non-PC platforms.
        symphonyPath = mfilename('fullpath');
        parentDir = fileparts(symphonyPath);
        addpath(fullfile(parentDir, filesep, 'Stubs'));
    else
        if isempty(getenv('PROCESSOR_ARCHITEW6432'))
            symphonyPath = 'C:\Program Files\Physion\Symphony\bin';
        else
            symphonyPath = 'C:\Program Files (x86)\Physion\Symphony\bin';
        end
        
        % Add Symphony.Core assemblies
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.Core.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.ExternalDevices.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'HekaDAQInterface.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.SimulationDAQController.dll'));
        
        NET.addAssembly('System.Windows.Forms');
    end
end
