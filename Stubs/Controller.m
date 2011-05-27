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
        
        function RunEpoch(obj, epoch, persistor) %#ok<INUSD>
            import Symphony.Core.*;
            
            epoch.StartTime = now;
            
            device = obj.GetDevice('test-device');
            duration = epoch.Stimuli.Item(device).Duration;
            sampleRate = obj.DAQController.GetStream('OUT').SampleRate;
            samples = duration * sampleRate.QuantityInBaseUnit;
            
            % Fill in a dummy response
            for i = 1:epoch.Responses.Count
                data = GenericList();
                for j = 1:samples
                    data.Add(Measurement((rand(1, 1) * 1000 - 500) / 1000000, 'A'));
                end
                epoch.Responses.Values{i}.Data = InputData(data, Measurement(10000, 'Hz'), now);
            end
        end
    end
end