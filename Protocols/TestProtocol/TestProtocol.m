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
        
        
        function [stimuli, sampleRate] = sampleStimuli(obj)
            stimuli = cell(obj.epochMax, 1);
            for i = 1:obj.epochMax
                stimuli{i} = obj.stimulusForEpoch(i);
            end
            sampleRate = 10000;
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.openFigure('Response');
            obj.openFigure('Custom', 'Name', 'Foo', ...
                                     'UpdateCallback', @updateFigure);
        end
        
        
        function updateFigure(obj, axesHandle)
            cla(axesHandle)
            set(axesHandle, 'XTick', [], 'YTick', []);
            text(0.5, 0.5, ['Epoch ' num2str(obj.epochNum)], 'FontSize', 48, 'HorizontalAlignment', 'center');
        end
        
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus, freqScale] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('freqScale', freqScale);
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
        end
        
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.epochNum < obj.epochMax;
            end
        end

    end
end