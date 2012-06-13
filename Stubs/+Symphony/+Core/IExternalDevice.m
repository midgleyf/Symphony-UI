%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IExternalDevice < Symphony.Core.ITimelineProducer
   
    properties
        Name
        Controller
        Background
        Streams
        Manufacturer
    end
    
    methods
        function obj = IExternalDevice(name, manufacturer, controller, background)
            obj = obj@Symphony.Core.ITimelineProducer();
            
            obj.Name = name;
            obj.Controller = controller;
            obj.Background = background;
            obj.Manufacturer = manufacturer;
            
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