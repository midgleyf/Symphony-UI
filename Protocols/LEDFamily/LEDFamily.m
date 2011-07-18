classdef LEDFamily < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.LEDFamily'
        version = 1
        displayName = 'LED Family'
    end
    
    properties
        sampleInterval = uint16(80);
        stimPoints = uint16(100);
        prePoints = uint16(1000);
        tailPoints = uint16(4000);
        baseLightAmplitude = 0.5;
        stepsInFamily = uint8(3);
        ampStepScale = 2.0;
        lightMean = 0.0;
        preSynapticHold = int16(-60);
        numberOfAverages = uint8(5);
        interpulseInterval = 0.6;
        continuousRun = false;
    end
    
    properties (Dependent = true, SetAccess = private)
        ampOfLastStep;
    end
    
    methods
        
        function [stimulus, lightAmplitude] = stimulusForEpoch(obj, epochNum)
            % Calculate the light amplitude for this epoch.
            phase = single(mod(epochNum - 1, obj.stepsInFamily));
            lightAmplitude = obj.baseLightAmplitude * obj.ampStepScale ^ phase;
            
            % Create the stimulus
            stimulus = ones(1, obj.prePoints + obj.stimPoints + obj.tailPoints) * obj.lightMean;
            stimulus(obj.prePoints:obj.prePoints+obj.stimPoints) = lightAmplitude;
        end
        
        
        function stimuli = sampleStimuli(obj)
            stimuli = cell(obj.stepsInFamily, 1);
            for i = 1:obj.stepsInFamily
                stimuli{i} = obj.stimulusForEpoch(i);
            end
        end
        
        
        function prepareEpoch(obj)
            [stimulus, lightAmplitude] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('lightAmplitude', lightAmplitude);
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            
            obj.setDeviceBackground('test-device', obj.lightMean);
            
            obj.recordResponse('test-device');
        end
        
        
        function stats = responseStatistics(obj)
            r = obj.response();
            
            stats.mean = mean(r);
            stats.var = var(r);
        end
        
        
        function completeEpoch(obj)
            pause on
            pause(obj.interpulseInterval);
        end
        
        
        function keepGoing = continueEpochGroup(obj)
            keepGoing = obj.epochNum < obj.stepsInFamily * obj.numberOfAverages;
        end
        
        
        function amp = get.ampOfLastStep(obj)
            amp = obj.baseLightAmplitude * obj.ampStepScale ^ (obj.stepsInFamily - 1);
        end

    end
end