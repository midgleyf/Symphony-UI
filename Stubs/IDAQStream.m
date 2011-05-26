classdef IDAQStream < ITimelineProducer
   
    properties
        Configuration
        Name
        SampleRate
        Active
        MeasurementConversionTarget
    end
    
    methods
        function obj = IDAQStream()
            obj = obj@ITimelineProducer();
            
            obj.Configuration = GenericDictionary();
            obj.Active = true;
        end
    end
end