classdef MultiClampDevice < Symphony.Core.ExternalDevice
   
    methods
        function obj = MultiClampDevice(name, controller, background)
            obj = obj@Symphony.Core.ExternalDevice(name, controller, background);
        end
    end
end