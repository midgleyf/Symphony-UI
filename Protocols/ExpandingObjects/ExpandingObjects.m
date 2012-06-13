%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef ExpandingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'Symphony.StimGL.ExpandingObjects'
        version = 1
        displayName = 'Expanding Objects'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        screenDist = 12.1;
        screenWidth = 22.2;
        screenWidthLeft = 10.7;
        screenHeight = 12.5;
        screenHeightBelow = 2.2;
        screenOriginHorzOffsetDeg = 58.6;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
        plotData
        photodiodeThreshold = 0.1;
    end

    properties
        spikePolThrLimRet = [Inf,1,100,1];
        testPulseAmp = -20;
        stimglDelay = 1.1;
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        interTrialIntMin = 1;
        interTrialIntMax = 2;
        backgroundColor = 0;
        numObjects = 1;
        objectColor = 1;
        objectPositionX = 20;
        objectPositionY = 10;
        objectStartSize = 1;
        objectExpansionRate = [5,10,20,40];
        object2PositionX = [-20,-10];
        object2PositionY = [0,10];
        object2ExpansionRate = [5,10,20,40];
    end
    
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object expansion rate if numObjects is one
            % or object expansion rates and object2 position if numObjects is two
            if obj.numObjects==1
                obj.trialTypes = obj.objectExpansionRate';
            elseif obj.numObjects==2
                obj.trialTypes=allcombs(obj.objectExpansionRate,obj.object2PositionX,obj.object2PositionY,obj.object2ExpansionRate);
            end
            obj.notCompletedTrialTypes=1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectExpansionRate)>1
                obj.plotData.meanExpansionRateResp = NaN(1,numel(obj.objectExpansionRate));
                obj.openFigure('Custom','Name','MeanExpansionRateRespFig','UpdateCallback',@updateMeanExpansionRateRespFig);
            end
            if obj.numObjects==2
                if numel(obj.object2PositionX)>1 || numel(obj.object2PositionY)>1
                    obj.plotData.meanObj2PositionResp = NaN(numel(obj.object2PositionY),numel(obj.object2PositionX));
                    obj.openFigure('Custom','Name','MeanObj2PositionRespFig','UpdateCallback',@updateMeanObj2PositionRespFig);
                end
                if numel(obj.object2ExpansionRate)>1
                    obj.plotData.meanObj2ExpansionRateResp = NaN(1,numel(obj.object2ExpansionRate));
                    obj.openFigure('Custom','Name','MeanObj2ExpansionRateRespFig','UpdateCallback',@updateMeanObj2ExpansionRateRespFig);
                end
            end 
        end
        
        function updateResponseFig(obj,axesHandle)
            data = 1000*obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.photodiodeLineHandle = line(obj.plotData.time,obj.response('Photodiode'),'Parent',axesHandle,'Color',[0.8 0.8 0.8]);
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o','LineStyle','none');
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
                set(obj.plotData.photodiodeLineHandle,'Ydata',obj.response('Photodiode'));
                set(obj.plotData.responseLineHandle,'Ydata',data);
                set(obj.plotData.spikeMarkerHandle,'Xdata',obj.plotData.time(obj.plotData.spikePts),'Ydata',data(obj.plotData.spikePts));
            end
            set(obj.plotData.stimBeginLineHandle,'Xdata',[obj.plotData.stimStart,obj.plotData.stimStart]);
            set(obj.plotData.stimEndLineHandle,'Xdata',[obj.plotData.stimStart+obj.stimTime,obj.plotData.stimStart+obj.stimTime]);
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanExpansionRateRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanExpansionRateRespHandle = line(obj.objectExpansionRate,obj.plotData.meanExpansionRateResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectExpansionRate)-1,max(obj.objectExpansionRate)+1],'Xtick',obj.objectExpansionRate);
                xlabel(axesHandle,'object expansion rate (degrees/s)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanExpansionRateRespHandle,'Ydata',obj.plotData.meanExpansionRateResp);
            end
            line(obj.plotData.epochObjectExpansionRate,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanObj2PositionRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanObj2PositionImageHandle = imagesc(flipud(obj.plotData.meanObj2PositionResp),'Parent',axesHandle); colorbar; axis image;
                set(axesHandle,'Box','off','TickDir','out','XTick',1:numel(obj.object2PositionX),'XTickLabel',obj.object2PositionX,'YTick',1:numel(obj.object2PositionY),'YTickLabel',fliplr(obj.object2PositionY));
                xlabel(axesHandle,'azimuth (degrees)');
                ylabel(axesHandle,'elevation (degrees)');
                title(axesHandle,'Mean response versus object2 position (spike count)');
            else
                set(obj.plotData.meanObj2PositionImageHandle,'Cdata',flipud(obj.plotData.meanObj2PositionResp));
            end
        end
        
        function updateMeanObj2ExpansionRateRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanObj2ExpansionRateRespHandle = line(obj.object2ExpansionRate,obj.plotData.meanObj2ExpansionRateResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.object2ExpansionRate)-1,max(obj.object2ExpansionRate)+1],'Xtick',obj.object2ExpansionRate);
                xlabel(axesHandle,'object2 expansion rate (degrees/s)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanObj2ExpansionRateRespHandle,'Ydata',obj.plotData.meanObj2ExpansionRateResp);
            end
            line(obj.plotData.epochObject2ExpansionRate,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            params.fps_mode = 'single';
            params.ftrack_change = 0;
            params.ftrackbox_w = 10;
            params.numObj = obj.numObjects;
            
            % Pick a combination of object expansion rates and object2 position from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectExpansionRate = obj.trialTypes(epochTrialType,1);
            obj.plotData.epochObjectExpansionRate = epochObjectExpansionRate;
            if obj.numObjects==2
                epochObject2PositionX = obj.trialTypes(epochTrialType,2);
                epochObject2PositionY = obj.trialTypes(epochTrialType,3);
                epochObject2ExpansionRate = obj.trialTypes(epochTrialType,4);
                obj.plotData.epochObject2PositionX = epochObject2PositionX;
                obj.plotData.epochObject2PositionY = epochObject2PositionY;
                obj.plotData.epochObject2ExpansionRate = epochObject2ExpansionRate;
            end
            
            % Determine object size in degrees as a function of time
            frameRate = double(GetRefreshRate(obj.stimGL));
            nStimFrames = round(obj.stimTime*frameRate);
            sizeVectorDeg = obj.objectStartSize:epochObjectExpansionRate/frameRate:obj.objectStartSize+epochObjectExpansionRate/frameRate*nStimFrames;
            if obj.numObjects==2
                sizeVectorDeg2 = obj.objectStartSize:epochObject2ExpansionRate/frameRate:obj.objectStartSize+epochObject2ExpansionRate/frameRate*nStimFrames;
            end
            
            % Determine object size and position at each frame in pixels
            % Pad object size vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenWidthLeftPix = obj.screenWidthLeft*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            leftEdgesPix = screenWidthLeftPix+screenDistPix*tand(obj.screenOriginHorzOffsetDeg-obj.objectPositionX-0.5*sizeVectorDeg);
            rightEdgesPix = screenWidthLeftPix+screenDistPix*tand(obj.screenOriginHorzOffsetDeg-obj.objectPositionX+0.5*sizeVectorDeg);
            bottomEdgesPix = screenHeightBelowPix+screenDistPix*tand(obj.objectPositionY-0.5*sizeVectorDeg);
            topEdgesPix = screenHeightBelowPix+screenDistPix*tand(obj.objectPositionY+0.5*sizeVectorDeg);
            XsizeVectorPix = rightEdgesPix-leftEdgesPix;
            YsizeVectorPix = topEdgesPix-bottomEdgesPix;
            XposVectorPix = leftEdgesPix+0.5*XsizeVectorPix;
            YposVectorPix = bottomEdgesPix+0.5*YsizeVectorPix;
            XsizeVectorPix =[XsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            YsizeVectorPix =[YsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            if obj.numObjects==2
                leftEdgesPix = screenWidthLeftPix+screenDistPix*tand(obj.screenOriginHorzOffsetDeg-epochObject2PositionX-0.5*sizeVectorDeg2);
                rightEdgesPix = screenWidthLeftPix+screenDistPix*tand(obj.screenOriginHorzOffsetDeg-epochObject2PositionX+0.5*sizeVectorDeg2);
                bottomEdgesPix = screenHeightBelowPix+screenDistPix*tand(epochObject2PositionY-0.5*sizeVectorDeg2);
                topEdgesPix = screenHeightBelowPix+screenDistPix*tand(epochObject2PositionY+0.5*sizeVectorDeg2);
                XsizeVectorPix2 = rightEdgesPix-leftEdgesPix;
                YsizeVectorPix2 = topEdgesPix-bottomEdgesPix;
                XposVectorPix2 = leftEdgesPix+0.5*XsizeVectorPix2;
                YposVectorPix2 = bottomEdgesPix+0.5*YsizeVectorPix2;
                XsizeVectorPix2 =[XsizeVectorPix2,zeros(1,(obj.postTime+10)*frameRate)];
                YsizeVectorPix2 =[YsizeVectorPix2,zeros(1,(obj.postTime+10)*frameRate)];
            end
            
            % Specify frame parameters in frame_vars.txt file
            % create frameVars matrix
            params.nFrames = numel(XsizeVectorPix);
            if obj.numObjects==1
                frameVars = zeros(params.nFrames,12);
                frameVars(:,1) = 0:params.nFrames-1; % frame number
                frameVars(1:numel(XposVectorPix),5) = XposVectorPix;
                frameVars(numel(XposVectorPix)+1:end,5) = XposVectorPix(end);
                frameVars(1:numel(YposVectorPix),6) = YposVectorPix;
                frameVars(numel(YposVectorPix)+1:end,6) = YposVectorPix(end);
                frameVars(:,7) = XsizeVectorPix;
                frameVars(:,8) = YsizeVectorPix;
            else % objects 1 and 2 on alternating lines
                frameVars = zeros(2*params.nFrames,12);
                frameVars(1:2:end,1) = 0:params.nFrames-1;
                frameVars(2:2:end,1) = 0:params.nFrames-1;
                frameVars(2:2:end,2) = 1; % objNum (obj1=0, obj2=1)
                frameVars(1:2:2*numel(XposVectorPix),5) = XposVectorPix;
                frameVars(2*numel(XposVectorPix)+1:end,5) = XposVectorPix(end);
                frameVars(2:2:2*numel(XposVectorPix2)+1,5) = XposVectorPix2;
                frameVars(2*numel(XposVectorPix2)+2:end,5) = XposVectorPix2(end);
                frameVars(1:2:2*numel(YposVectorPix),6) = YposVectorPix;
                frameVars(2*numel(YposVectorPix)+1:end,6) = YposVectorPix(end);
                frameVars(2:2:2*numel(YposVectorPix2)+1,6) = YposVectorPix2;
                frameVars(2*numel(YposVectorPix2)+2:end,6) = YposVectorPix2(end);
                frameVars(1:2:end,7) = XsizeVectorPix;
                frameVars(1:2:end,8) = YsizeVectorPix;
                frameVars(2:2:end,7) = XsizeVectorPix2;
                frameVars(2:2:end,8) = YsizeVectorPix2;
            end
            frameVars(:,4) = 1; % objType (ellipse=1)
            frameVars(:,10) = obj.objectColor;
            frameVars(:,12) = 1; % zScaled needs to be 1
            % write to text file in same folder as m file
            currentDir = cd;
            protocolDir = fileparts(mfilename('fullpath'));
            cd(protocolDir);
            fileID = fopen('frame_vars.txt','w');
            fprintf(fileID,'"frameNum" "objNum" "subFrameNum" "objType(0=box,1=ellipse,2=sphere)" "x" "y" "r1" "r2" "phi" "color" "z" "zScaled"');
            fclose(fileID);
            dlmwrite('frame_vars.txt',frameVars,'delimiter',' ','roffset',1,'-append');
            cd(currentDir);
            params.frame_vars = [protocolDir '/frame_vars.txt'];
            
            % Set number of delay frames for preTime
            params.delay = round((obj.stimglDelay+obj.preTime)*frameRate);
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectExpansionRate',epochObjectExpansionRate);
            if obj.numObjects==2
                obj.addParameter('epochObject2PositionX',epochObject2PositionX);
                obj.addParameter('epochObject2PositionY',epochObject2PositionY);
                obj.addParameter('epochObject2ExpansionRate',epochObject2ExpansionRate);
            end
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+obj.stimTime+obj.postTime)));
            stimulus(0.1*obj.rigConfig.sampleRate+1:0.2*obj.rigConfig.sampleRate) = 1e-12*obj.testPulseAmp;
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 0);
            Unpause(obj.stimGL);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
            % Find spikes
            data=1000*obj.response('Amplifier_Ch1');
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
            
            % Update epoch and mean response (spike count) versus object expansion rate and/or object2 expansion rate or position
            obj.plotData.time = 1/obj.rigConfig.sampleRate*(1:numel(data));
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold,1));
            if isempty(obj.plotData.stimStart)
                obj.plotData.stimStart = obj.preTime;
            end
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.epochResp = numel(find(spikeTimes>obj.plotData.stimStart & spikeTimes<obj.plotData.stimStart+2*obj.stimTime));
            if numel(obj.objectExpansionRate)>1
                objectExpansionRateIndex = find(obj.objectExpansionRate==obj.plotData.epochObjectExpansionRate,1);
                if obj.loopCount==1
                    obj.plotData.meanExpansionRateResp(objectExpansionRateIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanExpansionRateResp(objectExpansionRateIndex) = mean([repmat(obj.plotData.meanExpansionRateResp(objectExpansionRateIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if obj.numObjects==2
                if numel(obj.object2PositionX)>1 || numel(obj.object2PositionY)>1
                    object2PositionXIndex = find(obj.object2PositionX==obj.plotData.epochObject2PositionX,1);
                    object2PositionYIndex = find(obj.object2PositionY==obj.plotData.epochObject2PositionY,1);
                    if obj.loopCount==1
                        obj.plotData.meanObj2PositionResp(object2PositionYIndex,object2PositionXIndex) = obj.plotData.epochResp;
                    else
                        obj.plotData.meanObj2PositionResp(object2PositionYIndex,object2PositionXIndex) = mean([repmat(obj.plotData.meanObj2PositionResp(object2PositionYIndex,object2PositionXIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                    end
                end
                if numel(obj.object2ExpansionRate)>1
                    object2ExpansionRateIndex = find(obj.object2ExpansionRate==obj.plotData.epochObject2ExpansionRate,1);
                    if obj.loopCount==1
                        obj.plotData.meanObj2ExpansionRateResp(object2ExpansionRateIndex) = obj.plotData.epochResp;
                    else
                        obj.plotData.meanObj2ExpansionRateResp(object2ExpansionRateIndex) = mean([repmat(obj.plotData.meanObj2ExpansionRateResp(object2ExpansionRateIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                    end
                end
            end
            
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % if all stim sizes completed, reset notCompeletedSizes and start a new loop
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
            if keepGoing && obj.epochNum>0
                rng('shuffle');
                pause on;
                pause(rand(1)*(obj.interTrialIntMax-obj.interTrialIntMin)+obj.interTrialIntMin);
            end
        end
       
        function completeRun(obj)
            Stop(obj.stimGL);
            
            % Call the base class method.
            completeRun@SymphonyProtocol(obj);
        end
        
    end
    
end