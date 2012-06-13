%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IDAQController < Symphony.Core.ITimelineProducer & Symphony.Core.IHardwareController
   
    properties
        Streams
    end
    
    methods
        function obj = IDAQController()
            obj = obj@Symphony.Core.ITimelineProducer();
            
            obj.Streams = GenericDictionary();
        end
        
        function AddStream(obj, stream)
            obj.Streams.Add(stream.Name, stream);
        end
        
        function s = GetStream(obj, name)
            s = obj.Streams.Item(name);
        end
        
        function RequestStop(~)
        end
        
    end
end