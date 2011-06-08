classdef DAQOutputStream < Symphony.Core.IDAQOutputStream
    methods
        function obj = DAQOutputStream(name)
            obj = obj@Symphony.Core.IDAQOutputStream();
            
            obj.Name = name;
        end
    end
end