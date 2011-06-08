classdef OutputData < Symphony.Core.IOData
   
    properties
        IsLast
    end
    
    methods
        function obj = OutputData(data, sampleRate, isLast)
            obj = obj@Symphony.Core.IOData(data, sampleRate);
            
            obj.IsLast = isLast;
        end
    end
    
end