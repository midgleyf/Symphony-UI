%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef MovingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'Symphony.StimGL.MovingObjects'
        version = 1
        displayName = 'Moving Objects'
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
        preTime = 1;
        postTime = 2;
        interTrialIntMin = 1;
        interTrialIntMax = 2;
        backgroundColor = 0;
        objectColor = 1;
        objectSize = [5,20];
        RFcenterX = 400;
        RFcenterY = 300;
        Xoffset = 0;
        Yoffset = 0;
        objectSpeed = [10,30];
        objectDir = 0:45:315;
    end
    
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object size, speed, and direction
            obj.trialTypes = allcombs(obj.objectSize,obj.objectSpeed,obj.objectDir);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectSize)>1
                obj.plotData.meanSizeResp = NaN(1,numel(obj.objectSize));
                obj.openFigure('Custom','Name','MeanSizeRespFig','UpdateCallback',@updateMeanSizeRespFig);
            end
            if numel(obj.objectSpeed)>1
                obj.plotData.meanSpeedResp = NaN(1,numel(obj.objectSpeed));
                obj.openFigure('Custom','Name','MeanSpeedRespFig','UpdateCallback',@updateMeanSpeedRespFig);
            end
            if numel(obj.objectDir)>1
                obj.plotData.meanDirResp = NaN(1,numel(obj.objectDir));
                obj.openFigure('Custom','Name','MeanDirRespFig','UpdateCallback',@updateMeanDirRespFig);
            end
        end
        
        function updateResponseFig(obj,axesHandle)
            data = 1000*obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.photodiodeLineHandle = line(obj.plotData.time,obj.response('Photodiode'),'Parent',axesHandle,'Color',[0.8 0.8 0.8]);
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o','LineStyle','none');
                obj.plotData.stimBeginLineHandle = line([obj.plotData.stimStart,obj.plotData.stimStart],get(axesHandle,'YLim'),'Color','b','LineStyle',':');
                obj.plotData.stimEndLineHandle = line([obj.plotData.stimStart+obj.plotData.stimTime,obj.plotData.stimStart+obj.plotData.stimTime],get(axesHandle,'YLim'),'Color','b','LineStyle',':');
                obj.plotData.targetTimeLineHandle = line([obj.plotData.stimStart+obj.plotData.targetTime,obj.plotData.stimStart+obj.plotData.targetTime],get(axesHandle,'YLim'),'Color','r','LineStyle',':');
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
                set(obj.plotData.photodiodeLineHandle,'Xdata',obj.plotData.time,'Ydata',obj.response('Photodiode'));
                set(obj.plotData.responseLineHandle,'Xdata',obj.plotData.time,'Ydata',data);
                set(obj.plotData.spikeMarkerHandle,'Xdata',obj.plotData.time(obj.plotData.spikePts),'Ydata',data(obj.plotData.spikePts));
            end
            xlim(axesHandle,[0 max(obj.plotData.time)]);
            set(obj.plotData.stimBeginLineHandle,'Xdata',[obj.plotData.stimStart,obj.plotData.stimStart]);
            set(obj.plotData.stimEndLineHandle,'Xdata',[obj.plotData.stimStart+obj.plotData.stimTime,obj.plotData.stimStart+obj.plotData.stimTime]);
            set(obj.plotData.targetTimeLineHandle,'Xdata',[obj.plotData.stimStart+obj.plotData.targetTime,obj.plotData.stimStart+obj.plotData.targetTime]);
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle,obj.plotData.targetTimeLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanSizeRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSizeRespHandle = line(obj.objectSize,obj.plotData.meanSizeResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSize)-1,max(obj.objectSize)+1],'Xtick',obj.objectSize);
                xlabel(axesHandle,'object size (degrees)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanSizeRespHandle,'Ydata',obj.plotData.meanSizeResp);
            end
            line(obj.plotData.epochObjectSize,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanSpeedRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSpeedRespHandle = line(obj.objectSpeed,obj.plotData.meanSpeedResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSpeed)-1,max(obj.objectSpeed)+1],'Xtick',obj.objectSpeed);
                xlabel(axesHandle,'object speed (degrees/s)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanSpeedRespHandle,'Ydata',obj.plotData.meanSpeedResp);
            end
            line(obj.plotData.epochObjectSpeed,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanDirRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanDirRespHandle = line(obj.objectDir,obj.plotData.meanDirResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectDir)-10,max(obj.objectDir)+10],'Xtick',obj.objectDir);
                xlabel(axesHandle,'object direction (degrees relative to vertical)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanDirRespHandle,'Ydata',obj.plotData.meanDirResp);
            end
            line(obj.plotData.epochObjectDir,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
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
            
            % Pick a combination of object size/speed/direction from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectSize = obj.trialTypes(epochTrialType,1);
            epochObjectSpeed = obj.trialTypes(epochTrialType,2);
            epochObjectDir = obj.trialTypes(epochTrialType,3);
            obj.plotData.epochObjectSize = epochObjectSize;
            obj.plotData.epochObjectSpeed = epochObjectSpeed;
            obj.plotData.epochObjectDir = epochObjectDir;
            
            % Determine object path (get start and end postions in pixels)
            % (add offset so objects start and end just off the screen)
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenWidthLeftPix = obj.screenWidthLeft*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            XtargetDeg=obj.screenOriginHorzOffsetDeg-obj.RFcenterX+obj.Xoffset;
            YtargetDeg=obj.RFcenterY+obj.Yoffset;
            XtargetPix = screenWidthLeftPix+screenDistPix*tand(XtargetDeg);
            YtargetPix = screenHeightBelowPix+screenDistPix*tand(YtargetDeg);
            if epochObjectDir==0
                XstartPix = XtargetPix;
                YstartPix = 0;
                XendPix = XtargetPix;
                YendPix = obj.yMonPix;
                XstartOffsetDeg = 0;
                YstartOffsetDeg = -0.5*epochObjectSize;
                XendOffsetDeg = 0;
                YendOffsetDeg = 0.5*epochObjectSize;
            elseif epochObjectDir>0 && epochObjectDir<90
                m = tand(90-epochObjectDir);
                xintercept = XtargetPix-YtargetPix/m;
                yintercept = -m*xintercept;
                if xintercept<0
                    XstartPix = 0;
                    YstartPix = yintercept;
                    XstartOffsetDeg = -0.5*epochObjectSize;
                    YstartOffsetDeg = -0.5*epochObjectSize*m;
                else
                    XstartPix = xintercept;
                    YstartPix = 0;
                    XstartOffsetDeg = -0.5*epochObjectSize/m;
                    YstartOffsetDeg = -0.5*epochObjectSize;
                end
                XendPix = (obj.yMonPix-yintercept)/m;
                if XendPix>obj.xMonPix
                    XendPix=obj.xMonPix;
                    XendOffsetDeg = 0.5*epochObjectSize;
                else
                    XendOffsetDeg = 0.5*epochObjectSize/m;
                end
                YendPix = m*obj.xMonPix+yintercept;
                if YendPix>obj.yMonPix
                    YendPix=obj.yMonPix;
                    YendOffsetDeg = 0.5*epochObjectSize;
                else
                    YendOffsetDeg = 0.5*epochObjectSize*m;
                end
            elseif epochObjectDir==90
                XstartPix = 0;
                YstartPix = YtargetPix;
                XendPix = obj.xMonPix;
                YendPix = YtargetPix;
                XstartOffsetDeg = -0.5*epochObjectSize;
                YstartOffsetDeg = 0;
                XendOffsetDeg = 0.5*epochObjectSize;
                YendOffsetDeg = 0;
            elseif epochObjectDir>90 && epochObjectDir<180
                m = -tand(epochObjectDir-90);
                xintercept = XtargetPix-(obj.yMonPix-YtargetPix)/-m;
                yintercept = -m*xintercept;
                if xintercept<0
                    XstartPix = 0;
                    YstartPix = obj.yMonPix+yintercept;
                    XstartOffsetDeg = -0.5*epochObjectSize;
                    YstartOffsetDeg = 0.5*epochObjectSize*(-m);
                else
                    XstartPix = xintercept;
                    YstartPix = obj.yMonPix;
                    XstartOffsetDeg = -0.5*epochObjectSize/(-m);
                    YstartOffsetDeg = 0.5*epochObjectSize;
                end
                XendPix = (-obj.yMonPix-yintercept)/m;
                if XendPix>obj.xMonPix
                    XendPix=obj.xMonPix;
                    XendOffsetDeg = 0.5*epochObjectSize;
                else
                    XendOffsetDeg = 0.5*epochObjectSize/(-m);
                end
                YendPix = m*obj.xMonPix+yintercept;
                if YendPix<-obj.yMonPix
                    YendPix = 0;
                    YendOffsetDeg = -0.5*epochObjectSize;
                else
                    YendPix = obj.yMonPix+YendPix;
                    YendOffsetDeg = -0.5*epochObjectSize*(-m);
                end
            elseif epochObjectDir==180
                XstartPix = XtargetPix;
                YstartPix = obj.yMonPix;
                XendPix = XtargetPix;
                YendPix = 0;
                XstartOffsetDeg = 0;
                YstartOffsetDeg = 0.5*epochObjectSize;
                XendOffsetDeg = 0;
                YendOffsetDeg = -0.5*epochObjectSize;
            elseif epochObjectDir>180 && epochObjectDir<270
                m = tand(270-epochObjectDir);
                xintercept = -obj.xMonPix+XtargetPix+(obj.yMonPix-YtargetPix)/m;
                yintercept = -m*xintercept;
                if xintercept>0
                    XstartPix = obj.xMonPix;
                    YstartPix = obj.yMonPix+yintercept;
                    XstartOffsetDeg = 0.5*epochObjectSize;
                    YstartOffsetDeg = 0.5*epochObjectSize*m;
                else
                    XstartPix = obj.xMonPix+xintercept;
                    YstartPix = obj.yMonPix;
                    XstartOffsetDeg = 0.5*epochObjectSize/m;
                    YstartOffsetDeg = 0.5*epochObjectSize;
                end
                XendPix = (-obj.yMonPix-yintercept)/m;
                if XendPix<-obj.xMonPix
                    XendPix = 0;
                    XendOffsetDeg = -0.5*epochObjectSize;
                else
                    XendPix = obj.xMonPix+XendPix;
                    XendOffsetDeg = -0.5*epochObjectSize/m;
                end
                YendPix = m*-obj.xMonPix+yintercept;
                if YendPix<-obj.yMonPix
                    YendPix = 0;
                    YendOffsetDeg = -0.5*epochObjectSize;
                else
                    YendPix = obj.yMonPix+YendPix;
                    YendOffsetDeg = -0.5*epochObjectSize*m;
                end
            elseif epochObjectDir==270
                XstartPix = obj.xMonPix;
                YstartPix = YtargetPix;
                XendPix = 0;
                YendPix = YtargetPix;
                XstartOffsetDeg = 0.5*epochObjectSize;
                YstartOffsetDeg = 0;
                XendOffsetDeg = -0.5*epochObjectSize;
                YendOffsetDeg = 0;
            elseif epochObjectDir>270 && epochObjectDir<360
                m = -tand(epochObjectDir-270);
                xintercept = -obj.xMonPix+XtargetPix+YtargetPix/-m;
                yintercept = -m*xintercept;
                if xintercept>0
                    XstartPix = obj.xMonPix;
                    YstartPix = yintercept;
                    XstartOffsetDeg = 0.5*epochObjectSize;
                    YstartOffsetDeg = -0.5*epochObjectSize*(-m);
                else
                    XstartPix = obj.xMonPix+xintercept;
                    YstartPix = 0;
                    XstartOffsetDeg = 0.5*epochObjectSize/(-m);
                    YstartOffsetDeg = -0.5*epochObjectSize;
                end
                XendPix = (obj.yMonPix-yintercept)/m;
                if XendPix<-obj.xMonPix
                    XendPix = 0;
                    XendOffsetDeg = -0.5*epochObjectSize;
                else
                    XendPix = obj.xMonPix+XendPix;
                    XendOffsetDeg = -0.5*epochObjectSize/(-m);
                end
                YendPix = m*-obj.xMonPix+yintercept;
                if YendPix>obj.yMonPix
                    YendPix = obj.yMonPix;
                    YendOffsetDeg = 0.5*epochObjectSize;
                else
                    YendOffsetDeg = 0.5*epochObjectSize*(-m);
                end
            end
            
            % Determine number of frames to complete path and X and Y positions in degrees at each frame
            frameRate = double(GetRefreshRate(obj.stimGL));
            XstartDeg = atand((XstartPix-0.5*obj.xMonPix)/screenDistPix)+XstartOffsetDeg;
            XendDeg = atand((XendPix-0.5*obj.xMonPix)/screenDistPix)+XendOffsetDeg;
            YstartDeg = atand((YstartPix-screenHeightBelowPix)/screenDistPix)+YstartOffsetDeg;
            YendDeg = atand((YendPix-screenHeightBelowPix)/screenDistPix)+YendOffsetDeg;
            targetDistDeg = sqrt((XtargetDeg-XstartDeg)^2+(YtargetDeg-YstartDeg)^2);
            targetFrame = round(targetDistDeg/epochObjectSpeed*frameRate)+1;
            pathDistDeg = sqrt((XendDeg-XstartDeg)^2+(YendDeg-YstartDeg)^2);
            nStimFrames = round(pathDistDeg/epochObjectSpeed*frameRate)+1;
            if XendDeg==XstartDeg
                XposVectorDeg = XstartDeg*ones(1,nStimFrames);
            else
                XposVectorDeg = XstartDeg:(XendDeg-XstartDeg)/(nStimFrames-1):XendDeg;
            end
            if YendDeg==YstartDeg
                YposVectorDeg = YstartDeg*ones(1,nStimFrames);
            else
                YposVectorDeg = YstartDeg:(YendDeg-YstartDeg)/(nStimFrames-1):YendDeg;
            end
             
            % Determine object size and position at each frame in pixels
            % Pad object size vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            leftEdgesPix = screenWidthLeftPix+screenDistPix*tand(XposVectorDeg-0.5*epochObjectSize);
            rightEdgesPix = screenWidthLeftPix+screenDistPix*tand(XposVectorDeg+0.5*epochObjectSize);
            bottomEdgesPix = screenHeightBelowPix+screenDistPix*tand(YposVectorDeg-0.5*epochObjectSize);
            topEdgesPix = screenHeightBelowPix+screenDistPix*tand(YposVectorDeg+0.5*epochObjectSize);
            XsizeVectorPix = rightEdgesPix-leftEdgesPix;
            YsizeVectorPix = topEdgesPix-bottomEdgesPix;
            XposVectorPix = leftEdgesPix+0.5*XsizeVectorPix;
            YposVectorPix = bottomEdgesPix+0.5*YsizeVectorPix;
            XsizeVectorPix =[XsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            YsizeVectorPix =[YsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            
            % Specify frame parameters in frame_vars.txt file
            % create frameVars matrix
            params.nFrames = numel(XsizeVectorPix);
            frameVars = zeros(params.nFrames,12);
            frameVars(:,1) = 0:params.nFrames-1; % frame number
            frameVars(:,4) = 1; % objType (1=ellipse)
            frameVars(1:numel(XposVectorPix),5) = XposVectorPix;
            frameVars(numel(XposVectorPix)+1:end,5) = XposVectorPix(end);
            frameVars(1:numel(YposVectorPix),6) = YposVectorPix;
            frameVars(numel(YposVectorPix)+1:end,6) = YposVectorPix(end);
            frameVars(:,7) = XsizeVectorPix;
            frameVars(:,8) = YsizeVectorPix;
            frameVars(:,10) = obj.objectColor;
            frameVars(:,12) = 1; % zScaled needs to be 1
            % write to file
            currentDir = cd;
            protocolDir = fileparts(mfilename('fullpath'));
            cd(protocolDir);
            fileID = fopen('frame_vars.txt','w');
            fprintf(fileID,'"frameNum" "objNum" "subFrameNum" "objType(0=box,1=ellipse,2=sphere)" "x" "y" "r1" "r2" "phi" "color" "z" "zScaled"');
            fclose(fileID);
            dlmwrite('frame_vars.txt',frameVars,'delimiter',' ','roffset',1,'-append');
            cd(currentDir);
            params.frame_vars = [protocolDir '/frame_vars.txt'];
            
            % Set number of delay frames for preTime and determine stimTime and time to target
            params.delay = round((obj.stimglDelay+obj.preTime)*frameRate);
            stimTime = nStimFrames/frameRate;
            obj.plotData.stimTime = stimTime;
            targetTime = targetFrame/frameRate;
            obj.plotData.targetTime = targetTime;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectDir',epochObjectDir);
            obj.addParameter('epochObjectSpeed',epochObjectSpeed);
            obj.addParameter('epochObjectSize',epochObjectSize);
            obj.addParameter('stimFrames',nStimFrames);
            obj.addParameter('stimTime',stimTime);
            obj.addParameter('targetFrame',targetFrame);
            obj.addParameter('targetTime',targetTime);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+stimTime+obj.postTime)));
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
            
            % Update epoch and mean response (spike count) versus object speed and/or direction
            obj.plotData.time = 1/obj.rigConfig.sampleRate*(1:numel(data));
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold,1));
            if isempty(obj.plotData.stimStart)
                obj.plotData.stimStart = obj.preTime;
            end
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.epochResp = numel(find(spikeTimes>obj.plotData.stimStart+obj.plotData.targetTime-1 & spikeTimes<obj.plotData.stimStart+obj.plotData.targetTime+1));
            if numel(obj.objectSize)>1
                objectSizeIndex = find(obj.objectSize==obj.plotData.epochObjectSize,1);
                if obj.loopCount==1
                    obj.plotData.meanSizeResp(objectSizeIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanSizeResp(objectSizeIndex) = mean([repmat(obj.plotData.meanSizeResp(objectSizeIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if numel(obj.objectSpeed)>1
                objectSpeedIndex = find(obj.objectSpeed==obj.plotData.epochObjectSpeed,1);
                if obj.loopCount==1
                    obj.plotData.meanSpeedResp(objectSpeedIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanSpeedResp(objectSpeedIndex) = mean([repmat(obj.plotData.meanSpeedResp(objectSpeedIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if numel(obj.objectDir)>1
                objectDirIndex = find(obj.objectDir==obj.plotData.epochObjectDir,1);
                if obj.loopCount==1
                    obj.plotData.meanDirResp(objectDirIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanDirResp(objectDirIndex) = mean([repmat(obj.plotData.meanDirResp(objectDirIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
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