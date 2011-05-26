classdef IDAQInputStream < IDAQStream
   
    properties
        Devices
    end
    
    methods
        function obj = IDAQInputStream()
            obj = obj@IDAQStream();
            
            obj.Devices = GenericList();
        end
    end
end