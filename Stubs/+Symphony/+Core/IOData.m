classdef IOData < Symphony.Core.IIOData
   
    properties
        Time
    end
    
    methods
        function obj = IOData(data, sampleRate, deviceConfig, streamConfig)
            obj = obj@Symphony.Core.IIOData(data, sampleRate);
            
            obj.Time = [];
            
            if nargin > 3
                obj.ExternalDeviceConfiguration = deviceConfig;
            end
            if nargin > 4
                obj.StreamConfiguration = streamConfig;
            end
        end
    end
    
end