classdef DAQInputStream < IDAQInputStream
   
    methods
        function obj = DAQInputStream(name)
            obj = obj@IDAQInputStream();
            
            obj.Name = name;
        end
    end
end