classdef IDAQController < Symphony.Core.ITimelineProducer
   
    properties
        Streams
    end
    
    methods
        function obj = IDAQController()
            obj = obj@Symphony.Core.ITimelineProducer();
            
            obj.Streams = GenericDictionary();
        end
        
        function BeginSetup(obj) %#ok<MANU>
        end
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream.Name, stream);
        end
        
        function s = GetStream(obj, name)
            s = obj.Streams.Item(name);
        end
    end
end