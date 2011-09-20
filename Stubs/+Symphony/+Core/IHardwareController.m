classdef IHardwareController < handle
    
    properties
        Running
        Configuration
    end
    
    methods
        
        function obj = IHardwareController()
            obj.Running = false;
            obj.Configuration = GenericDictionary();
        end
        
        function Start(obj, ~)
            obj.Running = true;
        end
        
        function Stop(~)
            obj.Running = false;
        end
        
        function BeginSetup(~)
        end
        
    end
    
end