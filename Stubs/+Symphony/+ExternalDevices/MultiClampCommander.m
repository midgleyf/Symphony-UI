classdef MultiClampCommander < handle
   
    properties
        SerialNumber
        Channel
        Clock
    end
    
    methods
        function obj = MultiClampCommander(serialNumber, channel, clock)
            obj.SerialNumber = serialNumber;
            obj.Channel = channel;
            obj.Clock = clock;
        end
    end
end