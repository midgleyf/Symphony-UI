classdef IDAQStream < Symphony.Core.ITimelineProducer
   
    properties
        Configuration
        Name
        SampleRate
        Active
        MeasurementConversionTarget
    end
    
    methods
        function obj = IDAQStream()
            obj = obj@Symphony.Core.ITimelineProducer();
            
            obj.Configuration = GenericDictionary();
            obj.Active = true;
        end
    end
end