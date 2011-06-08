classdef SimulationDAQController < Symphony.Core.IDAQController 
   
    properties
        SampleRate
        SimulationRunner
    end
    
    methods
        function obj = SimulationDAQController()
            obj = obj@Symphony.Core.IDAQController ();
            
            obj.SampleRate = Symphony.Core.Measurement(100, 'Hz');
        end
    end
end