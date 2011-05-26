classdef IDAQOutputStream < IDAQStream
   
    properties
        Device
        HasMoreData
        Background
    end
    
    methods
        function obj = IDAQOutputStream()
            obj = obj@IDAQStream();
        end
    end
end