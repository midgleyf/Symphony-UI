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
            epoch.StartTime = now;
            
            % Create dummy responses.
            for i = 1:epoch.Responses.Count
                device = epoch.Responses.Keys{i};
                
                if epoch.Stimuli.ContainsKey(device)
                    % Copy the stimulii to the responses.
                    stimulus = epoch.Stimuli.Item(device);
                    epoch.Responses.Values{i}.Data = InputData(stimulus.Data.Data, stimulus.Data.SampleRate, now);
                else
                    % Generate one second of random noise for a response.
                    samples = 10000;
                    data = GenericList();
                    for j = 1:samples
                        data.Add(Measurement((rand(1, 1) * 1000 - 500) / 1000000, 'A'));
                    end
                    epoch.Responses.Values{i}.Data = InputData(data, Measurement(10000, 'Hz'), now);
                end
            end
        end
    end
end