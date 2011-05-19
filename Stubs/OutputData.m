classdef OutputData < IOData
   
    properties
        IsLast
    end
    
    methods
        function obj = OutputData(data, sampleRate, isLast)
            obj = obj@IOData(data, sampleRate);
            
            obj.IsLast = isLast;
        end
    end
    
end