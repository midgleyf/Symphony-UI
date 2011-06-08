classdef ITimelineProducer < handle
   
    properties
        Clock
    end
    
    methods
        function obj = ITimelineProducer()
            obj = obj@handle();
            
            obj.Clock = [];
        end
    end
end