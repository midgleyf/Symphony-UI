classdef Ipulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.Ipulse'
        version = 1
        displayName = 'I pulse'
    end
    
    properties (Hidden)
        loopCount
        plotData
    end
    
    properties
        samplingRate = 50000;
        preTime = 0.2;
        stimTime = 0.5;
        postTime = 0.3;
        Iamp=[-800:200:-200,-150:50:-50,-25:25:25,50:50:150,200:200:1000];
        interEpochInterval = 1.5;
        numberOfLoops = uint8(3);
    end
    
    methods
        
        function [stimuli,sampleRate] = sampleStimuli(obj)
            % Return a set of sample stimuli, one for each value in Iamp.
            obj.loopCount = 1;
            sampleRate = obj.samplingRate;
            stimuli = cell(length(obj.Iamp),1);
            for i = 1:length(obj.Iamp)
                stimuli{i} = obj.stimulusForEpoch(i);
            end
        end
        
        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
            % TODO: remove this once the base class is handling the sample rate
            obj.rigConfig.sampleRate = obj.samplingRate;
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figure
            sampInt=1/obj.samplingRate;
            obj.plotData.time=sampInt:sampInt:obj.preTime+obj.stimTime+obj.postTime;
            obj.openFigure('Custom','Name','Responses','UpdateCallback',@updateResponsesFig);
        end
            
        function updateResponsesFig(obj,axesHandle)
            if obj.epochNum==1
                xlabel(axesHandle,'s');
                ylabel(axesHandle,'mV');
                set(axesHandle,'Box','off','TickDir','out');
            else
                set(obj.plotData.prevLineHandle,'Color',[0.8 0.8 0.8]);
            end
            obj.plotData.prevLineHandle = line(obj.plotData.time,obj.response('Amplifier_Ch1'),'Parent',axesHandle,'Color','k');
            title(axesHandle,['Epoch ' num2str(obj.epochNum-numel(obj.Iamp)*(obj.loopCount-1)) ' of ' num2str(numel(obj.Iamp)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus,epochIamp] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('IAmp',epochIamp);
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
        end
        
        function [stimulus,epochIamp] = stimulusForEpoch(obj,epochNum)
            epochIamp = obj.Iamp(epochNum-numel(obj.Iamp)*(obj.loopCount-1));
            stimulus=zeros(1,obj.samplingRate*(obj.preTime+obj.stimTime+obj.postTime));
            stimulus(obj.samplingRate*obj.preTime+1:obj.samplingRate*(obj.preTime+obj.stimTime)) = epochIamp*1e-12;
        end
        
        function completeEpoch(obj)
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % if all I pulse ampitudes completed, start a new loop
            if ~rem(obj.epochNum,numel(obj.Iamp))
                obj.loopCount = obj.loopCount+1;
            end
        end
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if obj.numberOfLoops>0 && obj.loopCount>obj.numberOfLoops
                keepGoing = false;
            end
            % pause for inter-epoch interval
            if keepGoing
                pause on
                pause(obj.interEpochInterval);   
            end
        end
        
    end
    
end