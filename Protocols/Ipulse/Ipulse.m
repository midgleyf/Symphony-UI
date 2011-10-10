classdef Ipulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.Ipulse'
        version = 1
        displayName = 'I pulse'
    end
    
    properties
        repeats = uint8(3);
        interEpochInt = 1.5;
        prePts = uint16(2000);
        stimPts = uint16(5000);
        postPts = uint16(3000);
        Iamp=[-800:200:-200,-150:50:-50,-25:25:25,50:50:150,200:200:1000];
    end
    
    properties (Dependent = true, SetAccess = private)
        sampleInterval;    % in microseconds, dependent until we can alter the device sample rate
    end
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.openFigure('Custom', 'Name', 'Responses', 'UpdateCallback', @updateResponsesFig);
        end
        
        
        function [stimulus, epochIamp] = stimulusForEpoch(obj, epochNum)
            epochIamp = obj.Iamp(mod(epochNum - 1, length(obj.Iamp)) + 1);
            stimulus = zeros(1, obj.prePts+obj.stimPts+obj.postPts);
            stimulus(obj.prePts+1:obj.prePts+obj.stimPts) = epochIamp;
        end
        
        
        function [stimuli, sampleRate] = sampleStimuli(obj)
            % Return a set of stimuli, one for each value in Iamp.
            sampleRate = 10000;
            stimuli = cell(length(obj.Iamp), 1);
            for i = 1:length(obj.Iamp)
                stimuli{i} = obj.stimulusForEpoch(i);
            end
        end
        
            
        function updateResponsesFig(obj, axesHandle)
            sampInt=1/10000*1000;
            t=sampInt:sampInt:sampInt*double(obj.prePts+obj.stimPts+obj.postPts);
            prevLineHandle=findobj(axesHandle,'type','line','color','k');
            set(prevLineHandle,'color',[0.8 0.8 0.8]);
            hold(axesHandle,'on');
            plot(axesHandle,t,obj.response,'k');
            xlabel(axesHandle,'ms');
            ylabel(axesHandle,'mV');
        end
        
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus, epochIamp] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('IAmp', epochIamp);
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            obj.setDeviceBackground('test-device', 0);
        end
        
        
        function completeEpoch(obj)
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            pause on
            pause(obj.interEpochInt);
        end
        
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.epochNum < numel(obj.Iamp)*double(obj.repeats);
            end
        end
        
        
        function interval = get.sampleInterval(obj)
            interval = uint16(100);
        end
        
    end
end