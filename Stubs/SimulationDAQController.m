classdef SimulationDAQController < handle
   
    properties
        Clock
        SampleRate
    end
    
    methods
        function obj = SimulationDAQController()
            obj = obj@handle();
            
            obj.SampleRate = Measurement(100, 'hz');
        end
        
        function Setup(obj) %#ok<MANU>
        end
        
        function s = GetStream(obj, name) %#ok<INUSD,MANU>
            s = [];
        end
    end
end