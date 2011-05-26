classdef SimulationDAQController < IDAQController 
   
    properties
        SampleRate
        SimulationRunner
    end
    
    methods
        function obj = SimulationDAQController()
            obj = obj@IDAQController ();
            
            obj.SampleRate = Measurement(100, 'hz');
        end
    end
end