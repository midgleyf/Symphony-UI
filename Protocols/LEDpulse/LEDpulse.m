classdef LEDpulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.symphony.LEDpulse'
        version = 1
        displayName = 'LED pulse'
    end
    
    properties (Hidden)
        loopCount
        plotData
    end
    
    properties
        epochDur = 600;
        LEDpulseNum = 1;
        LEDpulseDelay = 200;
        LEDpulseDur = 1;
        LEDpulseInt = 5;
        LEDpulseAmp = 1;
        IpulseNum = 0;
        IpulseDelay = 200;
        IpulseDur = 2;
        IpulseInt = 10;
        IpulseAmp = 1000;
        interEpochInterval = 10;
        numberOfLoops = uint8(1);
    end
    
    methods
        
        function [stimuli,sampleRate] = sampleStimuli(obj)
            % Return a set of sample stimuli, one for each value in Iamp.
            obj.loopCount = 1;
            sampleRate = obj.rigConfig.sampleRate;
            [LEDstim,Istim] = obj.stimulusForEpoch();
            if any(LEDstim) && any(Istim)
                stimuli{1} = LEDstim/max(abs(LEDstim))+Istim/max(abs(Istim));
            elseif any(LEDstim)
                stimuli{1} = LEDstim;
            elseif any(Istim)
                stimuli{1} = Istim;
            else
                stimuli{1} = zeros(1,numel(LEDstim));
            end
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figure
            sampInt=1/obj.rigConfig.sampleRate;
            obj.plotData.time=sampInt:sampInt:obj.epochDur;
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
            obj.plotData.prevLineHandle = line(obj.plotData.time,1000*obj.response('Amplifier_Ch1'),'Parent',axesHandle,'Color','k');
            title(axesHandle,['Epoch ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [LEDstim,Istim] = obj.stimulusForEpoch(obj.epochNum);
            obj.addStimulus('LED','LED stimulus',LEDstim,'V');
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',Istim,'A');
        end
        
        function [LEDstim,Istim] = stimulusForEpoch(obj)
            LEDstim = zeros(1,obj.rigConfig.sampleRate/1000*obj.epochDur);
            LEDpulsePts = obj.rigConfig.sampleRate/1000*(obj.LEDpulseDelay+obj.LEDpulseInt*(0:obj.LEDpulseNum-1));
            for n=1:numel(LEDpulsePts)
                LEDstim(LEDpulsePts(n):LEDpulsePts(n)+obj.rigConfig.sampleRate/1000*obj.LEDpulseDur) = obj.LEDpulseAmp;
            end
            Istim = zeros(1,obj.rigConfig.sampleRate/1000*obj.epochDur);
            IpulsePts = obj.rigConfig.sampleRate/1000*(obj.IpulseDelay+obj.IpulseInt*(0:obj.IpulseNum-1));
            for n=1:numel(IpulsePts)
                Istim(IpulsePts(n):IpulsePts(n)+obj.rigConfig.sampleRate/1000*obj.IpulseDur) = 1e-12*obj.IpulseAmp;
            end
        end
        
        function completeEpoch(obj)
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            obj.loopCount = obj.loopCount+1;
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