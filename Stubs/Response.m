classdef Response < handle
   
    properties
        Data
    end
    
    methods
        function obj = Response()
            obj = obj@handle();
            
            obj.Data = InputData(GenericList(), Measurement(10000, 'hz'), now);
        end
    end
    
end