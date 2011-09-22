classdef Controller < Symphony.Core.ITimelineProducer
   
    properties
        DAQController
        Devices = {}
        Configuration
        HardwareControllers
        CurrentEpoch
    end
    
    methods
        
        function obj = Controller()
            obj = obj@Symphony.Core.ITimelineProducer();
        end
        
        
        function AddDevice(obj, device)
            obj.Devices{end + 1} = device;
        end
        
        
        function d = GetDevice(obj, deviceName)
            d = [];
            for device = obj.Devices
                if strcmp(device{1}.Name, deviceName)
                    d = device{1};
                end
            end
        end
        
        
        function persistor = BeginEpochGroup(obj, path, label, source)
            persistor = EpochXMLPersistor(path);
            
            keywords = NET.createArray('System.String', 0);
            properties = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
            identifier = System.Guid.NewGuid();
            startTime = obj.Clock.Now;
            persistor.BeginEpochGroup(label, source, keywords, properties, identifier, startTime);
        end
        
        
        function RunEpoch(obj, epoch, persistor)
            import Symphony.Core.*;
            
            obj.CurrentEpoch = epoch;
            epoch.StartTime = now;
            
            % Create dummy responses.
            for i = 1:epoch.Responses.Count
                device = epoch.Responses.Keys{i};
                
                if epoch.Stimuli.ContainsKey(device)
                    % Copy the stimulii to the responses.
                    stimulus = epoch.Stimuli.Item(device);
                    epoch.Responses.Values{i} = InputData(stimulus.Data.Data, stimulus.Data.SampleRate, now);
                else
                    % Generate one second of random noise for a response.
                    samples = 10000;
                    data = GenericList();
                    for j = 1:samples
                        data.Add(Measurement((rand(1, 1) * 1000 - 500) / 1000000, 'A'));
                    end
                    response = epoch.Responses.Values{i};
                    response.Data = data;
                    respones.InputTime = now;
                end
            end
            
            if ~isempty(persistor)
                persistor.Serialize(epoch);
            end
            
            obj.CurrentEpoch = [];
        end
        
        function EndEpochGroup(~, persistor)
            persistor.EndEpochGroup();
            persistor.CloseDocument();
        end
        
    end
end