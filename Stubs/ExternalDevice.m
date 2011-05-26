classdef ExternalDevice < ITimelineProducer
   
    properties
        Name
        Controller
        Background
        MeasurementConversionTarget
        Streams
    end
    
    methods
        function obj = ExternalDevice(name, controller, background)
            obj = obj@ITimelineProducer();
            
            obj.Name = name;
            obj.Controller = controller;
            obj.Background = background;
            
            obj.Streams = GenericDictionary();
            
            obj.Controller.Devices{end + 1} = obj;
        end
        
        function BindStream(obj, arg1, arg2)
            if nargin == 2
                obj.Streams.Add(arg1.Name, arg1);
            else
                obj.Streams.Add(arg1, arg2);
            end
        end
    end
end