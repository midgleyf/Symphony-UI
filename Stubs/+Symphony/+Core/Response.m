classdef Response < handle
   
    properties
        Data
    end
    
    methods
        function obj = Response()
            obj = obj@handle();
            
            obj.Data = Symphony.Core.InputData(GenericList(), Symphony.Core.Measurement(10000, 'Hz'), now);
        end
    end
    
end