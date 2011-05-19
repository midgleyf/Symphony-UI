classdef InputData < IOData
   
    properties
        InputTime
    end
    
    methods
        function obj = InputData(data, sampleRate, inputTime)
            obj = obj@IOData(data, sampleRate);
            
            obj.InputTime = inputTime;
        end
    end
    
end