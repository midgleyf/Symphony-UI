classdef Response < handle
   
    properties
        Data
        DataConfigurationSpans
        SampleRate
        InputTime
        Duration
    end
    
    methods
        function obj = Response()
            obj = obj@handle();
            
            obj.Data = GenericList();
            obj.DataConfigurationSpans = GenericList();
            obj.SampleRate = Symphony.Core.Measurement(10000, 'Hz');
            obj.InputTime = now;
            obj.Duration = 0;   % TODO: calculate from length of data and sample rate?
        end
    end
    
end