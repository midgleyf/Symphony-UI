classdef SimulationDAQController < Symphony.Core.DAQControllerBase
   
    properties
        SampleRate
        SimulationRunner
    end
    
    methods
        function obj = SimulationDAQController()
            obj = obj@Symphony.Core.DAQControllerBase ();
            
            obj.SampleRate = Symphony.Core.Measurement(100, 'Hz');
        end
        
        function now = Now(obj) %#ok<MANU>
            now = System.DateTimeOffset.Now;
        end
    end
end