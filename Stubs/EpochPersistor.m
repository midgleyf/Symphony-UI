classdef EpochPersistor < handle
   
    properties
    end
    
    methods
        function obj = EpochPersistor()
            obj = obj@handle();
        end
        
        function BeginEpochGroup(label, parents, sources)
        end
        
        function Serialize(epoch)
        end
        
        function EndEpochGroup()
        end
        
        function Close()
        end
    end
    
end