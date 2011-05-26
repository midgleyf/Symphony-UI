classdef IDAQController < ITimelineProducer
   
    properties
        Streams
    end
    
    methods
        function obj = IDAQController()
            obj = obj@ITimelineProducer();
            
            obj.Streams = GenericDictionary();
        end
        
        function Setup(obj) %#ok<MANU>
        end
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream.Name, stream);
        end
        
        function s = GetStream(obj, name)
            s = obj.Streams.Item(name);
        end
    end
end