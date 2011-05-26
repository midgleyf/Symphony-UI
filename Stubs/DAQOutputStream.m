classdef DAQOutputStream < IDAQOutputStream
    methods
        function obj = DAQOutputStream(name)
            obj = obj@IDAQOutputStream();
            
            obj.Name = name;
        end
    end
end