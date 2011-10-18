classdef MultiClampDevice < Symphony.Core.ExternalDeviceBase
   
    methods
        
        function obj = MultiClampDevice(name, controller, background)
            obj = obj@Symphony.Core.ExternalDeviceBase(name, 'AutoMate', controller, background);
        end
        
        
        function params = DeviceParametersForInput(~, ~)
            params.Data.OperatingMode = 'VClamp';
        end
        
        
        function params = DeviceParametersForOutput(~, ~)
            params.Data.OperatingMode = 'VClamp';
        end
        
    end
end