classdef IDAQOutputStream < Symphony.Core.IDAQStream
   
    properties
        Device
        HasMoreData
        Background
    end
    
    methods
        function obj = IDAQOutputStream()
            obj = obj@Symphony.Core.IDAQStream();
        end
    end
end