classdef IOData < IIOData
   
    properties
        Time
    end
    
    methods
        function obj = IOData(data, sampleRate)
            obj = obj@IIOData(data, sampleRate);
            
            obj.Time = [];
        end
    end
    
end