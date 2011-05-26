classdef Simulation < handle
   
    properties
        callback
    end
    
    methods
        function obj = Simulation(func)
            obj = obj@handle();
            
            obj.callback = func;
        end
    end
    
end