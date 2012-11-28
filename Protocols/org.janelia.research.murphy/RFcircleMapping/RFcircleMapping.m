%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef RFcircleMapping < StimGLProtocol
    
    % Protocol use circles of increasing size and plot spike rate as a
    % function of circle size and color

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'RFcircleMapping'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        Yfactor = 1
        Xfactor = 1
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
        plotData
        objectSize
        photodiodeThreshold = 2.5;
    end

    properties
        spikePolThrLimRet = [Inf,1,100,1];
        stimGLdelay = 1.11; %seconds
        preTime = 0.5; %seconds
        stimTime = 0.5; %seconds
        postTime = 0.5; %seconds
        intertrialIntervalMin = 1; %seconds
        intertrialIntervalMax = 2; %seconds
        backgroundColor = 0;
        objectColor = [0.5,1];
        objectStartDiam = 100; % microns
        objectGrowth = 20; % microns
        stepNumber = 5;       
    end
    
    properties (Dependent = true, SetAccess = private)
        finalSize;
        RFcenterX; 
        RFcenterY;
    end

    methods
        function RFcenterX = get.RFcenterX(obj)
            RFcenterX = 640; 
        end
        
        function RFcenterY = get.RFcenterY(obj) 
            RFcenterY = 360;
        end
        function finalSize = get.finalSize(obj)
            finalSize = obj.objectStartDiam + ((obj.stepNumber-1)*obj.objectGrowth);
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object color and size
            obj.objectSize = obj.objectStartDiam : obj.objectGrowth : (obj.objectStartDiam+((obj.stepNumber-1)*obj.objectGrowth));
            
            obj.trialTypes = allcombs(obj.objectColor,obj.objectSize);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectColor)>1
                obj.plotData.meanColorRespON = NaN(1,numel(obj.objectColor));
                obj.plotData.meanColorRespOFF = NaN(1,numel(obj.objectColor));
                obj.openFigure('Custom','Name','MeanColorRespFig','UpdateCallback',@updateMeanColorRespFig);
            end
            if numel(obj.objectSize)>1
                obj.plotData.meanSizeRespON = NaN(1,numel(obj.objectSize));
                obj.plotData.meanSizeRespOFF = NaN(1,numel(obj.objectSize));
                obj.openFigure('Custom','Name','MeanSizeRespFig','UpdateCallback',@updateMeanSizeRespFig);
            end
        end
        
        function updateResponseFig(obj,axesHandle)
            data = 1000 * obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o','LineStyle','none');
                obj.plotData.photodiodeLineHandle = line(obj.plotData.time,obj.response('Photodiode'),'Parent',axesHandle,'Color',[0.8 0.8 0.8]);
                obj.plotData.stimBeginLineHandle = line([obj.plotData.stimStart,obj.plotData.stimStart],get(axesHandle,'YLim'),'Color','b','LineStyle',':');
                obj.plotData.stimEndLineHandle = line([obj.plotData.stimStart+obj.stimTime,obj.plotData.stimStart+obj.stimTime],get(axesHandle,'YLim'),'Color','b','LineStyle',':');
                xlim(axesHandle,[0 max(obj.plotData.time)]);
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
                set(obj.plotData.photodiodeLineHandle,'Ydata',obj.response('Photodiode'));
            end
            set(obj.plotData.stimBeginLineHandle,'Xdata',[obj.plotData.stimStart,obj.plotData.stimStart]);
            set(obj.plotData.stimEndLineHandle,'Xdata',[obj.plotData.stimStart+obj.stimTime,obj.plotData.stimStart+obj.stimTime]);
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanColorRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanColorRespHandleON = line(obj.objectColor,obj.plotData.meanColorRespON,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                obj.plotData.meanColorRespHandleOFF = line(obj.objectColor,obj.plotData.meanColorRespOFF,'Parent',axesHandle,'Color','r','Marker','d','LineStyle','none','MarkerFaceColor','r');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectColor)-0.1,max(obj.objectColor)+0.1],'Xtick',obj.objectColor);
                xlabel(axesHandle,'object brightness (normalized)');
                ylabel(axesHandle,'responses: rd=OFF, ok=ON (spike count)');
            else
                set(obj.plotData.meanColorRespHandleON,'Ydata',obj.plotData.meanColorRespON);
                set(obj.plotData.meanColorRespHandleOFF,'Ydata',obj.plotData.meanColorRespOFF);
            end
            line(obj.plotData.epochObjectColor,obj.plotData.epochRespON,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
            line(obj.plotData.epochObjectColor,obj.plotData.epochRespOFF,'Parent',axesHandle,'Color','r','Marker','d','LineStyle','none');
        end
        
        function updateMeanSizeRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSizeRespHandleON = line(obj.objectSize,obj.plotData.meanSizeRespON,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                obj.plotData.meanSizeRespHandleOFF = line(obj.objectSize,obj.plotData.meanSizeRespOFF,'Parent',axesHandle,'Color','r','Marker','d','LineStyle','none','MarkerFaceColor','r');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSize)-1,max(obj.objectSize)+1],'Xtick',obj.objectSize);
                xlabel(axesHandle,'object diameter (microns)');
                ylabel(axesHandle,'responses: rd=OFF, ok=ON (spike count)');
            else
                set(obj.plotData.meanSizeRespHandleON,'Ydata',obj.plotData.meanSizeRespON);
                set(obj.plotData.meanSizeRespHandleOFF,'Ydata',obj.plotData.meanSizeRespOFF);
            end
            line(obj.plotData.epochObjectSize,obj.plotData.epochRespON,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
            line(obj.plotData.epochObjectSize,obj.plotData.epochRespOFF,'Parent',axesHandle,'Color','r','Marker','d','LineStyle','none');
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            params.ftrack_change = 0;
            params.ftrackbox_w = 20;
            params.ftrackbox_x = 20;
            params.ftrackbox_w = 20;
            
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
            params.objXinit = obj.RFcenterX;
            params.objYinit = obj.RFcenterY;
            objectSizeXPix = epochObjectSize / obj.Yfactor;
            objectSizeYPix = epochObjectSize / obj.Yfactor;
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = round((obj.stimGLdelay + obj.preTime)*frameRate);
            params.nFrames = round(obj.stimTime*frameRate);
            params.tFrames = params.nFrames;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            params.objLenX = [objectSizeXPix/ obj.Yfactor zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            params.objLenY = [objectSizeYPix/ obj.Yfactor zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectColor', epochObjectColor);
            obj.addParameter('epochObjectSize', epochObjectSize);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+obj.stimTime+obj.postTime)));
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 0);
            Unpause(obj.stimGL);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
            % Find spikes
            data= 1000 * obj.response('Amplifier_Ch1');
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
            obj.plotData.time = 1/obj.rigConfig.sampleRate*(1:numel(data));
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold,1));
            if isempty(obj.plotData.stimStart)
                obj.plotData.stimStart = obj.preTime;
            end
            obj.plotData.epochRespON = numel(find(spikeTimes>obj.plotData.stimStart & spikeTimes<obj.plotData.stimStart+obj.stimTime));
            obj.plotData.epochRespOFF = numel(find(spikeTimes>obj.plotData.stimStart+obj.stimTime & spikeTimes<obj.plotData.stimStart+2*obj.stimTime));
            if numel(obj.objectColor)>1
                objectColorIndex = find(obj.objectColor==obj.plotData.epochObjectColor,1);
                if isnan(obj.plotData.meanColorRespON(objectColorIndex)) || isnan(obj.plotData.meanColorRespOFF(objectColorIndex))
                    obj.plotData.meanColorRespON(objectColorIndex) = obj.plotData.epochRespON;
                    obj.plotData.meanColorRespOFF(objectColorIndex) = obj.plotData.epochRespOFF;
                else
                    obj.plotData.meanColorRespON(objectColorIndex) = mean([repmat(obj.plotData.meanColorRespON(objectColorIndex),1,obj.loopCount-1),obj.plotData.epochRespON]);
                    obj.plotData.meanColorRespOFF(objectColorIndex) = mean([repmat(obj.plotData.meanColorRespOFF(objectColorIndex),1,obj.loopCount-1),obj.plotData.epochRespOFF]);
                end
            end
            if numel(obj.objectSize)>1
                objectSizeIndex = find(obj.objectSize==obj.plotData.epochObjectSize,1);
                if isnan(obj.plotData.meanSizeRespON(objectSizeIndex)) || isnan(obj.plotData.meanSizeRespOFF(objectSizeIndex))
                    obj.plotData.meanSizeRespON(objectSizeIndex) = obj.plotData.epochRespON;
                    obj.plotData.meanSizeRespOFF(objectSizeIndex) = obj.plotData.epochRespOFF;
                else
                    obj.plotData.meanSizeRespON(objectSizeIndex) = mean([repmat(obj.plotData.meanSizeRespON(objectSizeIndex),1,obj.loopCount-1),obj.plotData.epochRespON]);
                    obj.plotData.meanSizeRespOFF(objectSizeIndex) = mean([repmat(obj.plotData.meanSizeRespOFF(objectSizeIndex),1,obj.loopCount-1),obj.plotData.epochRespOFF]);
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