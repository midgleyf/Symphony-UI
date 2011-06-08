classdef IDAQInputStream < Symphony.Core.IDAQStream
   
    properties
        Devices
    end
    
    methods
        function obj = IDAQInputStream()
            obj = obj@Symphony.Core.IDAQStream();
            
            obj.Devices = GenericList();
        end
    end
end