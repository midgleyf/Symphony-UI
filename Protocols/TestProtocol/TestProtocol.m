classdef TestProtocol < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.test'
        version = 1
        displayName = 'Test'
    end
    
    properties
        epochMax = uint8(4)
        stimSamples = uint32(100)
        rampFrequency = true
    end
    
    methods
        
        function [stimulus, freqScale] = stimulusForEpoch(obj, epochNum)
            if obj.rampFrequency
                freqScale = 1000.0 / double(epochNum);
            else
                freqScale = 1000.0;
            end
            stimulus = 1000.*sin((1:double(obj.stimSamples)) / freqScale);
        end
        
        
        function stimuli = sampleStimuli(obj)
            stimuli = cell(obj.epochMax, 1);
            for i = 1:obj.epochMax
                stimuli{i} = obj.stimulusForEpoch(i);
            end
        end
        
        
        function prepareEpoch(obj)
            [stimulus, freqScale] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('freqScale', freqScale);
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            
            obj.setDeviceBackground('test-device', 0);
            
            obj.recordResponse('test-device');
        end
        
        
        function stats = responseStatistics(obj)
            r = obj.response();
            
            stats.mean = mean(r);
            stats.var = var(r);
        end
        
        
        function keepGoing = continueEpochGroup(obj)
            keepGoing = obj.epochNum < obj.epochMax;
        end

    end
end