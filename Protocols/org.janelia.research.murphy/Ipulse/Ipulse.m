%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Ipulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'Symphony.Ipulse'
        version = 1
        displayName = 'I pulse'
    end
    
    properties (Hidden)
        loopCount
        plotData
    end
    
    properties
        preTime = 0.2;
        stimTime = 0.5;
        postTime = 0.3;
        Iamp=[-800:200:-200,-150:50:-50,-25:25:25,50:50:150,200:200:1000];
        interEpochInterval = 1.5;
        numberOfLoops = uint8(3);
    end
    
    methods
        
        function stimuli = sampleStimuli(obj)
            % Return a set of sample stimuli, one for each value in Iamp.
            obj.loopCount = 1;
            stimuli = cell(length(obj.Iamp),1);
            for i = 1:length(obj.Iamp)
                stimuli{i} = obj.stimulusForEpoch(i);
            end
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figure
            sampInt=1/obj.rigConfig.sampleRate;
            obj.plotData.time=sampInt:sampInt:obj.preTime+obj.stimTime+obj.postTime;
            obj.openFigure('Custom','Name','Responses','UpdateCallback',@updateResponsesFig);
        end
            
        function updateResponsesFig(obj,axesHandle)
            if obj.epochNum==1
                xlim([0,obj.plotData.time(end)]);
                xlabel(axesHandle,'s');
                ylabel(axesHandle,'mV');
                set(axesHandle,'Box','off','TickDir','out');
            else
                set(obj.plotData.prevLineHandle,'Color',[0.8 0.8 0.8]);
            end
            data = 1000*obj.response('Amplifier_Ch1');
            obj.plotData.prevLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
            dataRange = max(data)-min(data);
            ylim([min(data)-0.05*dataRange,max(data)+0.05*dataRange]);
            title(axesHandle,['Epoch ' num2str(obj.epochNum-numel(obj.Iamp)*(obj.loopCount-1)) ' of ' num2str(numel(obj.Iamp)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus,epochIamp] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('epochIAmp',epochIamp);
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
        end
        
        function [stimulus,epochIamp] = stimulusForEpoch(obj,epochNum)
            epochIamp = obj.Iamp(epochNum-numel(obj.Iamp)*(obj.loopCount-1));
            stimulus=zeros(1,obj.rigConfig.sampleRate*(obj.preTime+obj.stimTime+obj.postTime));
            stimulus(obj.rigConfig.sampleRate*obj.preTime+1:obj.rigConfig.sampleRate*(obj.preTime+obj.stimTime)) = 1e-12*epochIamp;
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
            if keepGoing && obj.epochNum>0
                pause on
                pause(obj.interEpochInterval);   
            end
        end
        
    end
    
end