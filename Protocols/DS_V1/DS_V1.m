%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef DS_V1 < StimGLProtocol
    
    % Protocol present moving bars in as much as 8 directions, and show
    % spike rates as a function of direction, speed and thickness of the
    % bar (in microns or time residency).
    % 0degres = horizontal right of center.

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 2
        displayName = 'Direction Selectivity'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        Xfactor = 1;
        Yfactor = 1; 
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
        plotData
        photodiodeThreshold = 2.5;
    end

    properties
        spikePolThrLimRet = [Inf,1,100,1];
        stimGLdelay = 1.11 ; % unpausing time for stimGL (sec)
        preTime = 1; % seconds
        postTime = 2; % seconds
        appTime = 1; % seconds
        dispTime = 1; % seconds
        intertrialIntervalMin = 1; % seconds
        intertrialIntervalMax = 2; % seconds
        backgroundColor = 0;
        objectColor = 1;
        RFdiameter = 150; % microns
        objectSizeX = 150; % microns
        objectSizeY = [10,20]; 
        unitObjSizeY= { 'microns', 'constant time residency (sec/um)' }
        objectSpeed = [10,30]; % um/sec
        objectDir = 0:45:315; % degres (sens trigonometrique)
    end
    
    properties (Dependent = true, SetAccess = private) 
        RFcenterX = NaN; 
        RFcenterY = NaN; 
    end

    methods
        
        function RFcenterX = get.RFcenterX(obj) 
            RFcenterX = 640; 
        end
        
        function RFcenterY = get.RFcenterY(obj) 
            RFcenterY = 360;
        end
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object size, speed, and direction
            obj.trialTypes = allcombs(obj.objectSizeY,obj.objectSpeed,obj.objectDir);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectSpeed)>1
                obj.plotData.meanSpeedResp = NaN(1,numel(obj.objectSpeed));
                obj.openFigure('Custom','Name','MeanSpeedRespFig','UpdateCallback',@updateMeanSpeedRespFig);
            end
            if numel(obj.objectDir)>1
                obj.plotData.meanDirResp = NaN(1,numel(obj.objectDir));
                obj.openFigure('Custom','Name','MeanDirRespFig','UpdateCallback',@updateMeanDirRespFig);
            end
            if numel(obj.objectSizeY)>1
                obj.plotData.meanSizeResp = NaN(1,numel(obj.objectSizeY));
                obj.openFigure('Custom','Name','MeanSizeRespFig','UpdateCallback',@updateMeanSizeRespFig);
            end
        end
        
        function updateResponseFig(obj,axesHandle)
            data = 1000 * obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o','LineStyle','none');
                obj.plotData.photodiodeLineHandle = line(obj.plotData.time,obj.response('Photodiode'),'Parent',axesHandle,'Color',[0.8 0.8 0.8]);
                obj.plotData.appTimeLineHandle = line([obj.plotData.stimStart,obj.plotData.stimStart],get(axesHandle,'YLim'),'Color','c','LineStyle',':');
                obj.plotData.stimBeginLineHandle = line([obj.plotData.stimStart+obj.appTime,obj.plotData.stimStart+obj.appTime],get(axesHandle,'YLim'),'Color','b','LineStyle',':');
                obj.plotData.stimEndLineHandle = line([obj.plotData.stimStart+obj.appTime+obj.plotData.stimTime,obj.plotData.stimStart+obj.appTime+obj.plotData.stimTime],get(axesHandle,'YLim'),'Color','r','LineStyle',':');
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
                set(obj.plotData.responseLineHandle,'Xdata',obj.plotData.time,'Ydata',data);
                set(obj.plotData.spikeMarkerHandle,'Xdata',obj.plotData.time(obj.plotData.spikePts),'Ydata',data(obj.plotData.spikePts));
                set(obj.plotData.photodiodeLineHandle,'Xdata',obj.plotData.time,'Ydata',obj.response('Photodiode'));
            end
            set(obj.plotData.appTimeLineHandle,'Xdata',[obj.plotData.stimStart,obj.plotData.stimStart]);
            set(obj.plotData.stimBeginLineHandle,'Xdata',[obj.plotData.stimStart+obj.appTime,obj.plotData.stimStart+obj.appTime]);
            set(obj.plotData.stimEndLineHandle,'Xdata',[obj.plotData.stimStart+obj.appTime+obj.plotData.stimTime,obj.plotData.stimStart+obj.appTime+obj.plotData.stimTime]);
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanSpeedRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSpeedRespHandle = line(obj.objectSpeed,obj.plotData.meanSpeedResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSpeed)-1,max(obj.objectSpeed)+1],'Xtick',obj.objectSpeed);
                xlabel(axesHandle,'object speed (um/s)');
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
                xlabel(axesHandle,'object direction (degrees relative to horizontal)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanDirRespHandle,'Ydata',obj.plotData.meanDirResp);
            end
            line(obj.plotData.epochObjectDir,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanSizeRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanSizeRespHandle = line(obj.objectSizeY,obj.plotData.meanSizeResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectSizeY)-10,max(obj.objectSizeY)+10],'Xtick',obj.objectSizeY);
                if strcmp(obj.unitObjSizeY,'microns')
                    xlabel(axesHandle, 'Bar Thickness (um)');
                else
                    xlabel(axesHandle, 'Bar time spend for each position (sec)');
                end
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
            params.mon_x_pix = obj.xMonPix;
            params.mon_y_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            params.ftrack_change = 0;
            params.ftrackbox_w = 20;
            params.ftrackbox_x = -25;
            params.ftrackbox_y = 20;
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = round((obj.stimGLdelay+obj.preTime)*frameRate);
            
            % Pick a combination of object size/speed/direction from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectSize = obj.trialTypes(epochTrialType,1);
            epochObjectSpeed = obj.trialTypes(epochTrialType,2);
            realObjectDir = obj.trialTypes(epochTrialType,3);
            epochObjectDir = realObjectDir -90;
            obj.plotData.epochObjectSpeed = epochObjectSpeed;
            obj.plotData.epochObjectDir = realObjectDir;
            obj.plotData.epochObjectSize = epochObjectSize;
  
            % Set trajectory for stimulus
            % set initial position for stim
            RFdiam= obj.RFdiameter / obj.Xfactor; 
            RFrayon = RFdiam/2; 
            trigoX=cosd(epochObjectDir);
            trigoY=sind(epochObjectDir);

            XstartPix = RFrayon*trigoX + obj.RFcenterX;
            XendPix = RFrayon*(-trigoX) + obj.RFcenterX;
            YstartPix = RFrayon*trigoY + obj.RFcenterY;
            YendPix = RFrayon*(-trigoY) + obj.RFcenterY;
            
            % Set object properties
            params.objLenY = obj.objectSizeX / obj.Xfactor;
            params.numObj = 1;
            params.objPhi = epochObjectDir ;
            if strcmp(obj.unitObjSizeY, 'microns')
                params.objLenX = epochObjectSize / obj.Yfactor;
            else
                params.objLenX = epochObjectSpeed*epochObjectSize / obj.Yfactor;
            end
                
            % Determine number of frames to complete path and X and Y positions in degrees at each frame
            frameRate = double(GetRefreshRate(obj.stimGL));
            distance= RFdiam;
            nStimFrames = round((distance/epochObjectSpeed)*frameRate);
            if XendPix==XstartPix
                pos_X_vector = XstartPix*ones(1,nStimFrames);
            else
                pos_X_vector = XstartPix:(XendPix-XstartPix)/(nStimFrames-1):XendPix;
            end
            if YendPix==YstartPix
                pos_Y_vector = YstartPix*ones(1,nStimFrames);
            else
                pos_Y_vector= YstartPix: (YendPix-YstartPix)/(nStimFrames-1):YendPix;
            end
            
            FrameNb = (obj.appTime + obj.dispTime)*frameRate + nStimFrames;
            appFrames = obj.appTime*frameRate;
            if strcmp(obj.unitObjSizeY, 'microns')
                XsizeVectorPix = [epochObjectSize / obj.Yfactor * ones(1,appFrames + nStimFrames),zeros(1,(obj.dispTime+5)*frameRate)];
            else
                XsizeVectorPix = [epochObjectSpeed*epochObjectSize / obj.Yfactor * ones(1,appFrames + nStimFrames),zeros(1,(obj.dispTime+5)*frameRate)];
            end
            YsizeVectorPix = [obj.objectSizeX / obj.Xfactor * ones(1,appFrames + nStimFrames),zeros(1,(obj.dispTime+5)*frameRate)];
            
            % Specify frame parameters in frame_vars.txt file
            % create frameVars matrix
                       
            params.nFrames = numel(XsizeVectorPix);
            frameVars = zeros(numel(XsizeVectorPix),12);
            frameVars(:,1) = 0:(numel(XsizeVectorPix)-1); % frame number
            frameVars(:,2) = 0; % object number
            frameVars(:,4) = 0; % objType (0=box)
            frameVars(1 : appFrames,5) = pos_X_vector(1);
            frameVars((appFrames+1) : (nStimFrames+appFrames),5) = pos_X_vector;
            frameVars((nStimFrames+appFrames+1) : FrameNb,5) = pos_X_vector(end);
            frameVars(FrameNb : end, 5) = 3000;
            frameVars(1 : appFrames,6) = pos_Y_vector(1);
            frameVars(appFrames+1 : (nStimFrames+appFrames),6) = pos_Y_vector;
            frameVars((nStimFrames+appFrames+1) : FrameNb,6) = pos_Y_vector(end);
            frameVars(FrameNb : end, 6) = 3000;
            frameVars(:,7) = XsizeVectorPix;
            frameVars(:,8) = YsizeVectorPix;
            frameVars(:,9) = epochObjectDir;
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

            % determine stimTime
            stimTime = nStimFrames/frameRate;
            obj.plotData.stimTime = stimTime;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectDir',realObjectDir);
            obj.addParameter('epochObjectSpeed',epochObjectSpeed);
            obj.addParameter('epochObjectSizeY',epochObjectSize);
            obj.addParameter('stimFrames',nStimFrames);
            obj.addParameter('stimTime',stimTime);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+obj.appTime+stimTime+obj.dispTime+obj.postTime)));
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
            
            % Update epoch and mean response (spike count) versus object speed and/or direction
            obj.plotData.time = 1/obj.rigConfig.sampleRate * (1:numel(data));
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold ,1));
            if isempty(obj.plotData.stimStart)
                obj.plotData.stimStart = obj.preTime;
            end
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.epochResp = numel(find(spikeTimes>obj.plotData.stimStart+obj.appTime & spikeTimes<obj.plotData.stimStart+obj.appTime+obj.plotData.stimTime));
            if numel(obj.objectSpeed)>1
                objectSpeedIndex = find(obj.objectSpeed==obj.plotData.epochObjectSpeed,1);
                if isnan(obj.plotData.meanSpeedResp(objectSpeedIndex))
                    obj.plotData.meanSpeedResp(objectSpeedIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanSpeedResp(objectSpeedIndex) = mean([repmat(obj.plotData.meanSpeedResp(objectSpeedIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if numel(obj.objectDir)>1
                objectDirIndex = find(obj.objectDir==obj.plotData.epochObjectDir,1);
                if isnan(obj.plotData.meanDirResp(objectDirIndex))
                    obj.plotData.meanDirResp(objectDirIndex) = obj.plotData.epochResp;
                else
                    obj.plotData.meanDirResp(objectDirIndex) = mean([repmat(obj.plotData.meanDirResp(objectDirIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
                end
            end
            if numel(obj.objectSizeY)>1
                objectSizeIndex = find(obj.objectSizeY==obj.plotData.epochObjectSize,1);
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
       
        function completeRun(obj)
            Stop(obj.stimGL);
            
            % Call the base class method.
            completeRun@SymphonyProtocol(obj);
        end
        
    end
    
end