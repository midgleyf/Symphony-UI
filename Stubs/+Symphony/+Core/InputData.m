classdef InputData < Symphony.Core.IOData
   
    properties
        InputTime
    end
    
    methods
        function obj = InputData(data, sampleRate, inputTime, config)
            if nargin < 4
                config = GenericDictionary();
            end
            
            obj = obj@Symphony.Core.IOData(data, sampleRate, config);
            
            obj.InputTime = inputTime;
        end
    end
    
end