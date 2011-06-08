classdef DAQInputStream < Symphony.Core.IDAQInputStream
   
    methods
        function obj = DAQInputStream(name)
            obj = obj@Symphony.Core.IDAQInputStream();
            
            obj.Name = name;
        end
    end
end