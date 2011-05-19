classdef Controller < handle
   
    properties
        DAQController
        Clock
        Devices = {}
    end
    
    methods
        function d = GetDevice(obj, deviceName)
            d = [];
            for device = obj.Devices
                if strcmp(device{1}.Name, deviceName)
                    d = device{1};
                end
            end
        end
        
        function RunEpoch(obj, epoch, persistor) %#ok<MANU,INUSD>
            % TODO: fill in dummy response?
            for i = 1:epoch.Stimuli.Count
                
            end
        end
    end
end