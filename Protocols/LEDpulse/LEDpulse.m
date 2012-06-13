%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef LEDpulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'Symphony.LEDpulse'
        version = 1
        displayName = 'LED pulse'
    end
    
    properties (Hidden)
        loopCount
        epochsPerLoop
        plotData
    end
    
    properties
        preTime = 200;
        postTime = 300;
        LEDpulseNum = 1;
        LEDpulseDelay = [0,1,2,4,10];
        LEDpulseDur = 1;
        LEDpulseInt = [5,10,20,40,100,500,1000];
        LEDpulseAmp = [0.5,1,2,4];
        IpulseNum = 0;
        IpulseDelay = 0;
        IpulseDur = 2;
        IpulseInt = 10;
        IpulseAmp = 1000;
        interEpochInterval = 10;
        numberOfLoops = uint8(1);
    end
    
    methods
        
        function stimuli = sampleStimuli(obj)
            % Return a set of sample stimuli
            numEpochs = max([numel(obj.LEDpulseDelay),numel(obj.LEDpulseInt),numel(obj.LEDpulseAmp)]);
            stimuli = cell(1, numEpochs);
            for i = 1:numEpochs
                [~, Istim, ~] = obj.stimulusForEpoch(i);
                stimuli{i} = Istim;
            end
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            obj.epochsPerLoop = max([numel(obj.LEDpulseDelay),numel(obj.LEDpulseInt),numel(obj.LEDpulseAmp)]);
            
            % Prepare figure
            obj.plotData.sampInt = 1/obj.rigConfig.sampleRate*1000;
            obj.openFigure('Custom','Name','Responses','UpdateCallback',@updateResponsesFig);
        end
            
        function updateResponsesFig(obj,axesHandle)
            if obj.epochNum==1
                xlabel(axesHandle,'ms');
                ylabel(axesHandle,'mV');
                set(axesHandle,'Box','off','TickDir','out');
            else
                set(obj.plotData.prevLineHandle,'Color',[0.8 0.8 0.8]);
            end
            data = 1000*obj.response('Amplifier_Ch1');
            obj.plotData.prevLineHandle = line(obj.plotData.sampInt:obj.plotData.sampInt:obj.plotData.sampInt*numel(data),data,'Parent',axesHandle,'Color','k');
            xlim([0,obj.plotData.sampInt*numel(data)]);
            dataRange = max(data)-min(data);
            ylim([min(data)-0.05*dataRange,max(data)+0.05*dataRange]);
            title(axesHandle,['Epoch ' num2str(obj.epochNum-obj.epochsPerLoop*(obj.loopCount-1)) ' of ' num2str(obj.epochsPerLoop) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [LEDstim,Istim,epochParam] = obj.stimulusForEpoch(obj.epochNum);
            if numel(obj.LEDpulseDelay>1)
                obj.addParameter('epochLEDpulseDelay',epochParam);
            elseif numel(obj.LEDpulseInt>1)
                obj.addParameter('epochLEDpulseInt',epochParam);
            elseif numel(obj.LEDpulseAmp>1)
                obj.addParameter('epochLEDpulseAmp',epochParam);
            end
            obj.addStimulus('LED','LED stimulus',LEDstim,'V');
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',Istim,'A');
        end
        
        function [LEDstim,Istim,epochParam] = stimulusForEpoch(obj,epochNum)
            if obj.LEDpulseNum>0
                if numel(obj.LEDpulseDelay)>1
                    epochParam = obj.LEDpulseDelay(epochNum-obj.epochsPerLoop*(obj.loopCount-1));
                    epochLEDpulseDelay = epochParam;
                    epochLEDpulseInt = obj.LEDpulseInt;
                    epochLEDpulseAmp = obj.LEDpulseAmp;
                elseif numel(obj.LEDpulseInt)>1
                    epochParam = obj.LEDpulseInt(epochNum-obj.epochsPerLoop*(obj.loopCount-1));
                    epochLEDpulseDelay = obj.LEDpulseDelay;
                    epochLEDpulseInt = epochParam;
                    epochLEDpulseAmp = obj.LEDpulseAmp;
                elseif numel(obj.LEDpulseAmp)>1
                    epochParam = obj.LEDpulseAmp(epochNum-obj.epochsPerLoop*(obj.loopCount-1));
                    epochLEDpulseDelay = obj.LEDpulseDelay;
                    epochLEDpulseInt = obj.LEDpulseInt;
                    epochLEDpulseAmp = epochParam;
                else
                    epochParam=[];
                    epochLEDpulseDelay = obj.LEDpulseDelay;
                    epochLEDpulseInt = obj.LEDpulseInt;
                    epochLEDpulseAmp = obj.LEDpulseAmp;
                end
                prePts = obj.rigConfig.sampleRate/1000*(obj.preTime+epochLEDpulseDelay);
                postPts = obj.rigConfig.sampleRate/1000*obj.postTime;
                LEDpulsePts = obj.rigConfig.sampleRate/1000*(1+epochLEDpulseInt*(0:obj.LEDpulseNum-1));
                stimPts = LEDpulsePts(end)+obj.rigConfig.sampleRate/1000*obj.LEDpulseDur;
                LEDstim = zeros(1,prePts+stimPts+postPts);
                for n=1:numel(LEDpulsePts)
                    LEDstim(prePts+LEDpulsePts(n):prePts+LEDpulsePts(n)+obj.rigConfig.sampleRate/1000*obj.LEDpulseDur) = epochLEDpulseAmp;
                end
            else
                epochParam = [];
                LEDstim = 0;
            end
            if obj.IpulseNum>0
                prePts = obj.rigConfig.sampleRate/1000*(obj.preTime+obj.IpulseDelay);
                postPts = obj.rigConfig.sampleRate/1000*obj.postTime;
                IpulsePts = obj.rigConfig.sampleRate/1000*(1+obj.IpulseInt*(0:obj.IpulseNum-1));
                stimPts = IpulsePts(end)+obj.rigConfig.sampleRate/1000*obj.IpulseDur;
                Istim = zeros(1,prePts+stimPts+postPts);
                for n=1:numel(IpulsePts)
                    Istim(prePts+IpulsePts(n):prePts+IpulsePts(n)+obj.rigConfig.sampleRate/1000*obj.IpulseDur) = 1e-12*obj.IpulseAmp;
                end
            else
                Istim = 0;
            end
            if numel(LEDstim)>numel(Istim)
                Istim = [Istim,zeros(1,numel(LEDstim)-numel(Istim))];
            elseif numel(Istim)>numel(LEDstim)
                LEDstim = [LEDstim,zeros(1,numel(Istim)-numel(LEDstim))];
            end
        end
        
        function completeEpoch(obj)
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            if obj.epochNum-obj.epochsPerLoop*(obj.loopCount-1)==obj.epochsPerLoop
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
            if keepGoing && obj.epochNum>0
                pause on
                pause(obj.interEpochInterval);   
            end
        end
        
    end
    
end