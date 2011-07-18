classdef UnitConvertingExternalDevice < Symphony.Core.ExternalDevice
   
    methods
        function obj = UnitConvertingExternalDevice(name, controller, background)
            obj = obj@Symphony.Core.ExternalDevice(name, controller, background);
        end
    end
end