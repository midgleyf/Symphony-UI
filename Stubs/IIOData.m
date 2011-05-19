classdef IIOData < handle
   
    properties
        Data                    % GenericList
        SampleRate              % Measurement
        ExternalDeviceConfig    % GenericDictionary
        StreamConfig            % GenericDictionary
        Duration
    end
    
    methods
        function obj = IIOData(data, sampleRate)
            obj = obj@handle();
            
            obj.Data = data;
            obj.SampleRate = sampleRate;
            obj.ExternalDeviceConfig = GenericDictionary();
            obj.StreamConfig = GenericDictionary();
            obj.Duration = obj.Data.Count / obj.SampleRate.Quantity;
        end
    end
    
end