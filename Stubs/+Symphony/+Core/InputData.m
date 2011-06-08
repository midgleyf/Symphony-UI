classdef InputData < Symphony.Core.IOData
   
    properties
        InputTime
    end
    
    methods
        function obj = InputData(data, sampleRate, inputTime, streamConfig, deviceConfig)
            if nargin < 4
                streamConfig = GenericDictionary();
            end
            if nargin < 5
                deviceConfig = GenericDictionary();
            end
            
            obj = obj@Symphony.Core.IOData(data, sampleRate, deviceConfig, streamConfig);
            
            obj.InputTime = inputTime;
        end
    end
    
end