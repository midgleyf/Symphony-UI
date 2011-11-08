classdef Circle < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Circle'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        screenDist = 12.8;
        screenWidth = 22.4;
        screenHeight = 12.6;
        screenHeightBelow = 3.3;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
        plotData
    end

    properties
        spikePolThrLimRet = [Inf,1,100,1];
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        intertrialIntervalMin = 1;
        intertrialIntervalMax = 2;
        backgroundColor = 0;
        objectColor = [0.5,1];
        objectSize = [1,5,10,20];
        RFcenterX = 0;
        RFcenterY = 0;
        Xoffset = 0;
        Yoffset = 0;
    end
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object color and size
            obj.trialTypes = allcombs(obj.objectColor,obj.objectSize);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            sampInt = 1/obj.rigConfig.sampleRate;
            obj.plotData.time = sampInt-obj.preTime:sampInt:obj.stimTime+obj.postTime;
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectColor)>1
                obj.plotData.meanColorResp = NaN(1,numel(obj.objectColor));
                obj.openFigure('Custom','Name','MeanColorRespFig','UpdateCallback',@updateMeanColorRespFig);
            end
            if numel(obj.objectSize)>1
                obj.plotData.meanSizeResp = NaN(1,numel(obj.objectSize));
                obj.openFigure('Custom','Name','MeanSizeRespFig','UpdateCallback',@updateMeanSizeRespFig);
            end
        end
        
        function updateResponseFig(obj,axesHandle)
            data = obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o');
                obj.plotData.stimBeginLineHandle = line([0,0],get(axesHandle,'YLim'),'Color','k','LineStyle',':');
                obj.plotData.stimEndLineHandle = line([obj.stimTime,obj.stimTime],get(axesHandle,'YLim'),'Color','k','LineStyle',':');
                xlabel(axesHandle,'s');
                ylabel(axesHandle,'mV');
                set(axesHandle,'Box','off','TickDir','out','Position',[0.1 0.1 0.85 0.8]);
                obj.plotData.epochCountHandle = uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.25 0.96 0.5 0.03],'FontWeight','bold');
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.17 0.915 0.075 0.03],'String','polarity');
                obj.plotData.polarityEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.255 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(1)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.35 0.915 0.075 0.03],'String','thresh');
                obj.plotData.threshEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.435 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(2)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.53 0.915 0.075 0.03],'String','limit');
                obj.plotData.limitEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.615 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(3)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.71 0.915 0.075 0.03],'String','return');
                obj.plotData.returnEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.795 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(4)));
            else
                set(obj.plotData.responseLineHandle,'Ydata',data);
                set(obj.plotData.spikeMarkerHandle,'Xdata',obj.plotData.time(obj.plotData.spikePts),'Ydata',data(obj.plotData.spikePts));
            end
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanColorRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanColorRespHandle = line(obj.objectColor,obj.plotData.meanColorResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectColor)-0.1,max(obj.objectColor)+0.1],'Xtick',obj.objectColor);
                xlabel(axesHandle,'object brightness (normalized)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanColorRespHandle,'Ydata',obj.plotData.meanColorResp);
            end
            line(obj.plotData.epochObjectColor,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanSizeRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSizeRespHandle = line(obj.objectSize,obj.plotData.meanSizeResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSize)-1,max(obj.objectSize)+1],'Xtick',obj.objectSize);
                xlabel(axesHandle,'object diameter (degrees)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanSizeRespHandle,'Ydata',obj.plotData.meanSizeResp);
            end
            line(obj.plotData.epochObjectSize,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Pick a combination of object color and size from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectColor = obj.trialTypes(epochTrialType,1);
            epochObjectSize = obj.trialTypes(epochTrialType,2);
            obj.plotData.epochObjectColor = epochObjectColor;
            obj.plotData.epochObjectSize = epochObjectSize;
            
            % Set object properties
            params.numObj = 1;
            params.objColor = epochObjectColor;
            params.objType = 'ellipse';
            % get object position and size in pixels
            objectPosDeg = [obj.RFcenterX+obj.Xoffset,obj.RFcenterY+obj.Yoffset];
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            objectEdgesXPix = obj.xMonPix/2+screenDistPix*tand([objectPosDeg(1)-epochObjectSize/2,objectPosDeg(1)+epochObjectSize/2]);
            objectEdgesYPix = screenHeightBelowPix+screenDistPix*tand([objectPosDeg(2)-epochObjectSize/2,objectPosDeg(2)+epochObjectSize/2]);
            objectSizeXPix = diff(objectEdgesXPix);
            objectSizeYPix = diff(objectEdgesYPix);
            params.objXinit = objectEdgesXPix(1)+objectSizeXPix/2;
            params.objYinit = objectEdgesYPix(1)+objectSizeYPix/2;
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = round(obj.preTime*frameRate);
            params.nFrames = round(obj.stimTime*frameRate);
            params.tFrames = params.nFrames;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            params.objLenX = [objectSizeXPix zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            params.objLenY = [objectSizeYPix zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectColor', epochObjectColor);
            obj.addParameter('epochObjectSize', epochObjectSize);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+obj.stimTime+obj.postTime)));
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 1);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
            % Find spikes
            data=obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                polarity = obj.spikePolThrLimRet(1);
                threshold = obj.spikePolThrLimRet(2);
                limitThresh = obj.spikePolThrLimRet(3);
                returnThresh = obj.spikePolThrLimRet(4);
            else
                polarity = str2double(get(obj.plotData.polarityEditHandle,'String'));
                threshold = str2double(get(obj.plotData.threshEditHandle,'String'));
                limitThresh = str2double(get(obj.plotData.limitEditHandle,'String'));
                returnThresh = str2double(get(obj.plotData.returnEditHandle,'String'));
            end
            % flip data and threshold if negative-going spike peaks
            if polarity<0
                data=-data; 
                threshold=-threshold;
                limitThresh=-limitThresh;
                returnThresh=-returnThresh;
            end
            % find sample number of spike peaks
            obj.plotData.spikePts=[];
            posThreshCross=find(data>=threshold,1);
            while ~isempty(posThreshCross)
                negThreshCross=posThreshCross+find(data(posThreshCross+1:end)<=returnThresh,1);
                if isempty(negThreshCross)
                    break;
                end
                [peak peakIndex]=max(data(posThreshCross:negThreshCross));
                if peak<limitThresh
                    obj.plotData.spikePts(end+1)=posThreshCross-1+peakIndex;
                end
                posThreshCross=negThreshCross+find(data(negThreshCross+1:end)>=threshold,1);
            end
            
            % Update epoch and mean response (spike count) versus object color and/or size
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.epochResp = numel(find(spikeTimes>0 & spikeTimes<obj.stimTime));
            if numel(obj.objectColor)>1
                objectColorIndex = find(obj.objectColor==obj.plotData.epochObjectColor,1);
                if isnan(obj.plotData.meanColorResp(objectColorIndex))
                    obj.plotData.meanColorResp(objectColorIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanColorResp(objectColorIndex) = mean([repmat(obj.plotData.meanColorResp(objectColorIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if numel(obj.objectSize)>1
                objectSizeIndex = find(obj.objectSize==obj.plotData.epochObjectSize,1);
                if isnan(obj.plotData.meanSizeResp(objectSizeIndex))
                    obj.plotData.meanSizeResp(objectSizeIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanSizeResp(objectSizeIndex) = mean([repmat(obj.plotData.meanSizeResp(objectSizeIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % if all trial types completed, reset completedTrialTypes and start a new loop
            if isempty(obj.notCompletedTrialTypes)
                obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
                obj.loopCount = obj.loopCount+1;
            end
        end
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if obj.numberOfLoops>0 && obj.loopCount>obj.numberOfLoops
                keepGoing = false;
            end
            % pause for random inter-epoch interval
            if keepGoing
                rng('shuffle');
                pause on;
                pause(rand(1)*(obj.intertrialIntervalMax-obj.intertrialIntervalMin)+obj.intertrialIntervalMin);
            end
        end
        
    end
    
end