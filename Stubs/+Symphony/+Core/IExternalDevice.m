classdef IExternalDevice < Symphony.Core.ITimelineProducer
   
    properties
        Name
        Controller
        Background
        Streams
    end
    
    methods
        function obj = IExternalDevice(name, controller, background)
            obj = obj@Symphony.Core.ITimelineProducer();
            
            obj.Name = name;
            obj.Controller = controller;
            obj.Background = background;
            
            obj.Streams = GenericDictionary();
            
            obj.Controller.AddDevice(obj);
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