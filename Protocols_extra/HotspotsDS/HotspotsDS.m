%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef HotspotsDS < StimGLProtocol
    
    % Protocol present moving bars in 1 direction +/- jitter, and show
    % spike rates as a function of position of the bar on the receptor
    % field, showing spike frequency increase
    % bar (in microns or time residency).
    % 0degres = horizontal right of center.

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'HotspotsDS'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        Xfactor = 1 
        Yfactor = 1 
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
        plotData
        circleLogic
        photodiodeThreshold = 2.5;
    end

    properties
        spikePolThrLimRet = [Inf,1,100,1];
        stimGLdelay = 1.11; % seconds.
        preTime = 1; % seconds, time before apparition of the stimulus
        postTime = 1; % seconds, time after completion of the stimulus
        appTime = 1; % seconds, time before movement start
        dispTime = 1; % seconds, time after ending the movement
        intertrialIntervalMin = 1; % seconds
        intertrialIntervalMax = 2; % seconds
        backgroundColor = 0;
        objectColor = [0,5,1];
        RFdiameter = 300; % microns
        objectSizeL = 20; % microns
        objectSizeT = 0.2; 
        unitObjSizeT= {'constant time residency (sec/um)','microns' }
        objectSpeed = [100,300]; % um/sec
        objectPrefDir = 0; % degres (sens trigonometrique: horizontal right)
        objectDirJitter = 0; % +/- degres
        nullDirectionStim = false % if true stim are going in preffered and null direction
        figureBinSize = 0.1 % seconds
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
        
            trialCheck = round(obj.RFdiameter / obj.objectSizeL);
            totalTrial = obj.RFdiameter / obj.objectSizeL;
            if totalTrial ~= trialCheck
                display('RFdiameter have to be a multiple of objectSizeL'); 
            end
            
            halfSize = obj.objectSizeL/2;
            halfTrials = totalTrial /2;
            
            if round(halfTrials) == halfTrials
                Trials = ones(1,halfTrials);
                    for n = 1:numel(Trials)
                        Trials(n)= halfSize + (n-1)*obj.objectSizeL;
                    end
            else
                Trials = ones(1,ceil(halfTrials));
                    for n = 1:numel(Trials);
                        Trials(n) = (n-1)*obj.objectSizeL;
                    end   
            end
            
            if obj.objectDirJitter ~= 0
                anglevariation = [(obj.objectPrefDir - obj.objectDirJitter) , obj.objectPrefDir , (obj.objectPrefDir + obj.objectDirJitter)];
            else
                anglevariation = obj.objectPrefDir;
            end
        
            if obj.nullDirectionStim == false
                objectDir = anglevariation;
            else
                objectNullDir = anglevariation + 180;
                objectDir = [anglevariation , objectNullDir];
            end    

            obj.circleLogic = logical([0,1]);
            obj.trialTypes = allcombs(Trials,obj.objectSpeed,objectDir,obj.circleLogic);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            obj.plotData.meanResp = NaN(obj.yMonPix , obj.xMonPix);
            obj.openFigure('Custom','Name','PrefDirRespFig','UpdateCallback',@updateMeanRespFig);
%             if numel(obj.objectSpeed)>1
%                 obj.plotData.meanSpeedResp = NaN(1,numel(obj.objectSpeed));
%                 obj.openFigure('Custom','Name','MeanSpeedRespFig','UpdateCallback',@updateMeanSpeedRespFig);
%             end
             if numel(objectDir)>1
                 for n= 1:numel(objectDir)
                    obj.plotData.meanDirResp{n} = NaN(obj.yMonPix , obj.xMonPix);
                    obj.openFigure('Custom','Name','VariableDirRespFig','UpdateCallback',@updateMeanDirRespFig);
                 end
             end

        end
        
        function updateResponseFig(obj,axesHandle)
            data = 1000 * obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Parent',axesHandle,'Color','k');
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Parent',axesHandle,'Color','g','Marker','o','LineStyle','none');
                obj.plotData.photodiodeLineHandle = line(obj.plotData.time,obj.response('Photodiode'),'Parent',axesHandle,'Color','b');
                obj.plotData.stimBeginLineHandle = line([obj.preTime,obj.preTime],get(axesHandle,'YLim'),'Color','r','LineStyle',':');
                obj.plotData.spikingDelayLineHandle = line ([obj.plotData.spikingDelay,obj.plotData.spikingDelay],get(axesHandle,'YLim'),'Color','k','LineStyle',':');
                obj.plotData.stimEndLineHandle = line([obj.preTime+obj.plotData.stimTime,obj.preTime+obj.plotData.stimTime],get(axesHandle,'YLim'),'Color','r','LineStyle',':');
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
                set(obj.plotData.spikingDelayLineHandle, 'Xdata', obj.plotData.spikingDelay,'Ydata', get(axesHandle,'YLim')); 
                % pas sur du X / Y ici
                set(obj.plotData.photodiodeLineHandle,'Xdata',obj.plotData.time,'Ydata',obj.response('Photodiode'));
            end
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.RespImageHandle = imagesc(flipud(obj.plotData.meanResp),'Parent',axesHandle); colorbar; axis image;
                set(axesHandle,'Box','off','TickDir','out');
                obj.plotData.respCountHandle = uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.25 0.96 0.5 0.03],'FontWeight','bold');
                xlabel(axesHandle,'positionX (pixels)');
                ylabel(axesHandle,'positionY (pixels)');
                title(axesHandle,'Spatial response (spike count)');
            else
                set(obj.plotData.RespImageHandle,'Cdata',flipud(obj.plotData.meanResp));
            end
            set(obj.plotData.respCountHandle,'String',['prefered direction=' num2str(obj.objectPrefDir)]);
 
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
            
            
            % Pick a combination of object size/speed/direction from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectTrialD = obj.trialTypes(epochTrialType,1);
            epochObjectSpeed = obj.trialTypes(epochTrialType,2);
            epochObjectDir = obj.trialTypes(epochTrialType,3);
            epochCircleLogic = obj.trialTypes(epochTrialType,4);
            obj.plotData.epochObjectSpeed = epochObjectSpeed;
            obj.plotData.epochObjectDir = epochObjectDir;
            obj.plotData.epochCircleLogic = epochCircleLogic;
            
            
            % Set constant object properties
            params.objLenY = obj.objectSizeL / obj.Xfactor;
            params.numObj = 1;
            
            % Set starting and ending position for stim using trigonometry 
            RFrayon= (obj.RFdiameter / obj.Xfactor)/2 ;
            obj.plotData.RFrayon = RFrayon;
            theta = 2*acosd(epochObjectTrialD/RFrayon); % angle between starting and ending points of the chord. 
            obj.plotData.epochTheta = theta;
            epsilon = 90 - (theta/2); %angle between 0 and starting point of chord.
            
            if epochCircleLogic == true
                
                trigoXstart = cosd(epochObjectDir -90 + epsilon);
                trigoYstart = sind(epochObjectDir -90 + epsilon);
                trigoXend = cosd(epochObjectDir -90 + epsilon + theta);
                trigoYend = sind(epochObjectDir -90 + epsilon + theta);
            else
                trigoXstart = cosd(epochObjectDir -90 - epsilon);
                trigoYstart = sind(epochObjectDir -90 - epsilon);
                trigoXend = cosd(epochObjectDir -90 - epsilon - theta);
                trigoYend = sind(epochObjectDir -90 - epsilon - theta);
            end
                    
            XstartPix = RFrayon*trigoXstart + obj.RFcenterX;
            XendPix = RFrayon*trigoXend + obj.RFcenterX;
            YstartPix = RFrayon*trigoYstart + obj.RFcenterY;
            YendPix = RFrayon*trigoYend + obj.RFcenterY;
                       
            
            % Set variable parameters
            params.objPhi = epochObjectDir -90 ;
            if strcmp(obj.unitObjSizeT, 'microns')
                params.objLenX = obj.objectSizeT / obj.Yfactor;
            else
                params.objLenX = epochObjectSpeed*obj.objectSizeT / obj.Yfactor;
            end
                
            % Determine number of frames to complete path and X and Y positions at each frame
            frameRate = double(GetRefreshRate(obj.stimGL));
            distance= RFrayon * sqrt(2-2*cosd(theta));
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
            
            % Determine total frame number
            % Pad object size vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            FrameNb = (obj.appTime + obj.dispTime)*frameRate + nStimFrames;
            preFrames = obj.appTime*frameRate;
            if strcmp(obj.unitObjSizeT, 'microns')
               YsizeVectorPix = [obj.objectSizeT / obj.Yfactor * ones(1,FrameNb),zeros(1,5*frameRate)];
            else
               YsizeVectorPix = [epochObjectSpeed * obj.objectSizeT / obj.Yfactor * ones(1,FrameNb),zeros(1,5*frameRate)];
            end  
            XsizeVectorPix = [obj.objectSizeL / obj.Xfactor * ones(1,FrameNb),zeros(1,5*frameRate)];
            
            % Specify frame parameters in frame_vars.txt file
            % create frameVars matrix
            params.nFrames = numel(XsizeVectorPix);
            frameVars = zeros(numel(XsizeVectorPix),12);
            frameVars(:,1) = 0:(numel(XsizeVectorPix)-1); % frame number
            frameVars(:,2) = 0; % object number
            frameVars(:,4) = 0; % objType (0=box)
            frameVars(1 : preFrames,5) = pos_X_vector(1);
            frameVars((preFrames+1) : (nStimFrames+preFrames),5) = pos_X_vector;
            frameVars((nStimFrames+preFrames+1) : FrameNb,5) = pos_X_vector(end);
            frameVars(FrameNb : end, 5) = 3000;
            frameVars(1 : preFrames,6) = pos_Y_vector(1);
            frameVars(preFrames+1 : (nStimFrames+preFrames),6) = pos_Y_vector;
            frameVars((nStimFrames+preFrames+1) : FrameNb,6) = pos_Y_vector(end);
            frameVars(FrameNb : end, 6) = 3000;
            frameVars(:,7) = YsizeVectorPix;
            frameVars(:,8) = XsizeVectorPix;
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

            % Set number of delay frames for preTime and determine stimTime
            params.delay = round(obj.preTime*frameRate);
            stimTime = nStimFrames/frameRate;
            obj.plotData.stimTime = stimTime + obj.appTime + obj.dispTime;
%             obj.plotData.Xvector = pos_X_vector;
%             obj.plotData.Yvector = pos_Y_vecor;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectDir',epochObjectDir);
            obj.addParameter('epochObjectSpeed',epochObjectSpeed);
            obj.addParameter('epochObjectD',epochObjectTrialD);
            obj.addParameter('epochCircleLogic',epochCircleLogic);
            obj.addParameter('stimFrames',nStimFrames);
            obj.addParameter('stimTime',stimTime);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+obj.appTime+stimTime+obj.dispTime+obj.postTime)));
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
%             SetParams(obj.stimGL, obj.plugInName, params);
%             Start(obj.stimGL, obj.plugInName, 1);
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 0);
            Unpause(obj.stimGL);

        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
            % Find spikes
            data= 1000* obj.response('Amplifier_Ch1');
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
            sampInt = 1/obj.rigConfig.sampleRate;
            obj.plotData.time = sampInt:sampInt:obj.preTime+obj.plotData.stimTime+obj.postTime;
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            
            % Add the new figure
            
%             obj.plotData.epochResp = numel(find(spikeTimes>obj.preTime & spikeTimes<obj.preTime+obj.plotData.stimTime));
%             if numel(obj.objectSpeed)>1
%                 objectSpeedIndex = find(obj.objectSpeed==obj.plotData.epochObjectSpeed,1);
%                 if isnan(obj.plotData.meanSpeedResp(objectSpeedIndex))
%                     obj.plotData.meanSpeedResp(objectSpeedIndex) = obj.plotData.epochResp;
%                 else
%                     obj.plotData.meanSpeedResp(objectSpeedIndex) = mean([repmat(obj.plotData.meanSpeedResp(objectSpeedIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
%                 end
%             end
%             if numel(obj.objectDir)>1
%                 objectDirIndex = find(obj.objectDir==obj.plotData.epochObjectDir,1);
%                 if isnan(obj.plotData.meanDirResp(objectDirIndex))
%                     obj.plotData.meanDirResp(objectDirIndex) = obj.plotData.epochResp;
%                 else
%                     obj.plotData.meanDirResp(objectDirIndex) = mean([repmat(obj.plotData.meanDirResp(objectDirIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
%                 end
%             end
%           Update mean responses (spike count)

            obj.plotData.time = 1/obj.rigConfig.sampleRate*(1:numel(data));
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold,1));
            if isempty(obj.plotData.stimStart)
                obj.plotData.stimStart = obj.preTime;
            end
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
           % distanceX = obj.plotData.Xvector(end) - obj.plotData.Xvector(1); %could be negative...
            % ici la trajectoire est la bonne, angulaire, mais ce n'est pas
            % pratique car je ne trouve pas un moyen de donner l'angle
            % correct au champ recepteur / barre qui le parcoure 
%             obj.plotData.Xvector = pos_X_vector; in HotspotsDS.m
%             obj.plotData.Yvector = pos_Y_vecor;
            % une alternative a moindre cout: afficher avec pcolor le RF
            % sans la rotation, la taille de la grille peut ainsi etre
            % fixer en fonction de la taille de la barre. (on pourras alors
            % eventuellement sauver l'image puis la faire tourner avec
            % imrorate function) --> ca ne conserve pas la taille, mais ca
            % peut etre pratique pour overlay avec lakshmi soft.
            % --> remove obj.plotData.X / Yvector in HotspotsDS.         
            % Rebuild starting and ending position for the figure (without
            % theta)
            
            RFcenterX= 640;
            RFcenterY= 360;

            epsilon = 90 - (obj.plotData.epochTheta/2);
            
            if obj.plotData.epochCircleLogic == true
                trigoXstart = cosd(epsilon);
                trigoYstart = sind(epsilon);
            else
                trigoXstart = cosd(-epsilon);
                trigoYstart = sind(-epsilon);
            end
                    
            XstartPix = obj.plotData.RFrayon * trigoXstart + RFcenterX;
            YstartPix = obj.plotData.RFrayon * trigoYstart + RFcenterY;
            
            
            % Define the different position explored by the bar
            distance = obj.plotData.RFrayon * sqrt(2-2*cosd(obj.plotData.epochTheta));
            A = find(spikeTimes>obj.plotData.stimStart);
            if numel(A)==0
                spikingDelay = 0;
            else
                spikingDelay = A(1) - obj.plotData.stimStart;
            end
            obj.plotData.spikingDelay = spikingDelay + obj.plotData.stimStart;
            preBin = obj.plotData.stimStart + obj.appTime + spikingDelay;
            travelTime = distance/obj.plotData.epochObjectSpeed ;
            binNb = round(travelTime / obj.figureBinSize); % peut etre ca vaux le coup de mettre un param enregistrant la taille reelle du Bin (si l'image est sauvee)
            binSpatialSize = distance / (travelTime / obj.figureBinSize); 
            
            Y1 = round(YstartPix - 1/2 * obj.objectSizeL);  
            Yend = round(YstartPix + 1/2 * obj.objectSizeL);
            
            for n=1:binNb
                X1 = round(XstartPix - n * binSpatialSize) ;                
                Xend = round(XstartPix - (n-1) * binSpatialSize);
                binSpikes = numel(find(spikeTimes> preBin + (n-1) * (travelTime / binNb) & spikeTimes< preBin + n * (travelTime / binNb)));
                
                    if obj.loopCount==1
                        obj.plotData.meanResp(Y1:Yend,X1:Xend)= binSpikes;
                    else
                        obj.plotData.meanResp(Y1:Yend,X1:Xend)= mean([repmat(obj.plotData.meanResp(X1:Xend,Y1:Yend),1,obj.loopCount-1),binSpikes]);
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