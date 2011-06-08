classdef IIOData < handle
   
    properties
        Data                           % GenericList
        SampleRate                     % Measurement
        ExternalDeviceConfiguration    % GenericDictionary
        StreamConfiguration            % GenericDictionary
        Duration
    end
    
    methods
        function obj = IIOData(data, sampleRate)
            obj = obj@handle();
            
            obj.Data = data;
            obj.SampleRate = sampleRate;
            obj.ExternalDeviceConfiguration = GenericDictionary();
            obj.StreamConfiguration = GenericDictionary();
            obj.Duration = obj.Data.Count / obj.SampleRate.Quantity;
        end
    end
    
end