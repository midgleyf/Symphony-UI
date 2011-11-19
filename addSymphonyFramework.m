function addSymphonyFramework()
    if isempty(which('NET.convertArray'))
        % Use the .NET stub classes instead of the real thing on non-PC platforms.
        symphonyPath = mfilename('fullpath');
        parentDir = fileparts(symphonyPath);
        addpath(fullfile(parentDir, filesep, 'Stubs'));
    else
        symphonyPath = 'C:\Program Files\Physion\Symphony\bin';
        
        % Add Symphony.Core assemblies
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.Core.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.ExternalDevices.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'HekaDAQInterface.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.SimulationDAQController.dll'));
        
        NET.addAssembly('System.Windows.Forms');
    end
end
