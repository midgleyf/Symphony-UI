classdef SealAndLeakProtocol < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.sealandleak'
        version = 1
        displayName = 'Seal and Leak'
    end
    
    properties
        epochDuration = uint32(100)     % milliseconds
        pulseDuration = uint32(50)      % milliseconds
        pulseAmplitude = 5              % picoamperes or millivolts
        background = 0                  % picoamperes or millivolts
    end
    
    
    properties (Dependent = true, SetAccess = private)
        mode
    end
    
    
    methods
        
        function obj = SealAndLeakProtocol()
            obj = obj@SymphonyProtocol();
            
            obj.allowSavingEpochs = false;
        end
        
        
        function stimulus = stimulusForDevice(obj, deviceName)
            sampleRate = obj.deviceSampleRate(deviceName, 'OUT');
            epochSamples = floor(double(obj.epochDuration) / 1000.0 * sampleRate.Quantity);
            pulseSamples = floor(double(obj.pulseDuration) / 1000.0 * sampleRate.Quantity);
            pulseStart = floor((epochSamples - pulseSamples) / 2.0);
            stimulus = ones(1, epochSamples) * obj.background;
            stimulus(pulseStart:pulseStart + pulseSamples - 1) = ones(1, pulseSamples) * obj.pulseAmplitude + obj.background;
        end
        
        
        function [stimuli, sampleRate] = sampleStimuli(obj)
            stimuli = {obj.stimulusForDevice('test-device')};
            sampleRate = obj.deviceSampleRate('test-device', 'OUT').Quantity;
        end
        
        
        function m = get.mode(obj)
            device = obj.controller.GetDevice('test-device');
            try
                m = char(device.DeviceParametersForInput(System.DateTimeOffset.Now).Data.OperatingMode);
            catch ME
                if (isa(ME, 'NET.NetException'))
                    message = char(ME.ExceptionObject.Message);
                else
                    message = ME.message;
                end
                if strncmp('No device parameters', message, 20)
                    m = 'Toggle MultiClamp mode';
                else
                    m = ['unknown (' message ')'];
                end
            end
        end
        
        
        function prepareRun(obj)
            obj.openFigure('Response');
            obj.openFigure('Mean Response');
        end
        
        
        function prepareEpoch(obj)
            import Symphony.Core.*
            
            stimulus = obj.stimulusForDevice('test-device');
            
            if strcmp(obj.mode, 'currentClamp')
                obj.addStimulus('test-device', 'test-stimulus', stimulus * 1e-9, 'A');
                obj.setDeviceBackground('test-device', obj.background * 1e-9, 'A');
            else
                obj.addStimulus('test-device', 'test-stimulus', stimulus * 1e-3, 'V');
                obj.setDeviceBackground('test-device', obj.background * 1e-3, 'V');
            end
            
            obj.recordResponse('test-device');
        end
        
        
        function keepGoing = continueRun(~)
            keepGoing = true;
        end

    end
end