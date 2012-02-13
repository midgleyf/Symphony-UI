classdef Circle < StimGLProtocol

    properties (Constant)
        identifier = 'Symphony.StimGL.Circle'
        version = 1
        displayName = 'Circle'
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
        preTime = 0.5;
        postTime = 0.5;
        interTrialIntMin = 1;
        interTrialIntMax = 2;
        backgroundColor = 0;
        objectColor = [0.5,1];
        objectSize = [1,5,10,20];
        RFcenterX = 60;
        RFcenterY = 10;
        Xoffset = 0;
        Yoffset = 0;
        numFlashes = 1;
        flashDur = [0.1,0.5];
        interFlashInt = [0.5,1];
    end
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Get all combinations of trial types based on object color, size, and flash duration and inter-flash interval
            obj.trialTypes = allcombs(obj.objectColor,obj.objectSize,obj.flashDur,obj.interFlashInt);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            if numel(obj.objectColor)>1
                obj.plotData.meanColorResp = NaN(1,numel(obj.objectColor));
                obj.openFigure('Custom','Name','MeanColorRespFig','UpdateCallback',@updateMeanColorRespFig);
            end
            if numel(obj.objectSize)>1
                obj.plotData.meanSizeResp = NaN(1,numel(obj.objectSize));
                obj.openFigure('Custom','Name','MeanSizeRespFig','UpdateCallback',@updateMeanSizeRespFig);
            end
            if numel(obj.flashDur)>1
                obj.plotData.meanFlashDurResp = NaN(1,numel(obj.flashDur));
                obj.openFigure('Custom','Name','MeanFlashDurRespFig','UpdateCallback',@updateMeanFlashDurRespFig);
            end
            if obj.numFlashes>1
                if numel(obj.interFlashInt)>1
                    obj.plotData.meanInterFlashIntResp = NaN(1,numel(obj.interFlashInt));
                    obj.openFigure('Custom','Name','MeanInterFlashIntRespFig','UpdateCallback',@updateMeanInterFlashIntRespFig);
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
                obj.plotData.stimEndLineHandle = line([obj.plotData.stimStart+obj.plotData.stimTime,obj.plotData.stimStart+obj.plotData.stimTime],get(axesHandle,'YLim'),'Color','b','LineStyle',':');
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
            set(obj.plotData.stimBeginLineHandle,'Xdata',[obj.plotData.stimStart,obj.plotData.stimStart]);
            set(obj.plotData.stimEndLineHandle,'Xdata',[obj.plotData.stimStart+obj.plotData.stimTime,obj.plotData.stimStart+obj.plotData.stimTime]);
            set([obj.plotData.stimBeginLineHandle,obj.plotData.stimEndLineHandle],'Ydata',get(axesHandle,'YLim'));
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.trialTypes,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.trialTypes,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanColorRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanColorRespHandle = line(obj.objectColor,obj.plotData.meanColorResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.objectColor)-0.01,max(obj.objectColor)+0.01],'Xtick',obj.objectColor);
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
        
        function updateMeanFlashDurRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanFlashDurRespHandle = line(obj.flashDur,obj.plotData.meanFlashDurResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.flashDur)-1,max(obj.flashDur)+1],'Xtick',obj.flashDur);
                xlabel(axesHandle,'object diameter (degrees)');
                ylabel(axesHandle,'response (spike count)');
            else
                set(obj.plotData.meanFlashDurRespHandle,'Ydata',obj.plotData.meanFlashDurResp);
            end
            line(obj.plotData.epochFlashDur,obj.plotData.epochResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
        end
        
        function updateMeanInterFlashIntRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.meanInterFlashIntRespHandle = line(obj.interFlashInt,obj.plotData.meanInterFlashIntResp,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none','MarkerFaceColor','k');
                set(axesHandle,'Box','off','TickDir','out','XLim',[min(obj.interFlashInt)-1,max(obj.interFlashInt)+1],'Xtick',obj.interFlashInt);
                xlabel(axesHandle,'object diameter (degrees)');
                ylabel(axesHandle,'response ratio (flash2/flash1)');
            else
                set(obj.plotData.meanInterFlashIntRespHandle,'Ydata',obj.plotData.meanInterFlashIntResp);
            end
            line(obj.plotData.epochInterFlashInt,obj.plotData.epochFlashRespRatio,'Parent',axesHandle,'Color','k','Marker','o','LineStyle','none');
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
            params.numObj = 1;
            
            % Pick a combination of object color and size from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectColor = obj.trialTypes(epochTrialType,1);
            epochObjectSize = obj.trialTypes(epochTrialType,2);
            epochFlashDur = obj.trialTypes(epochTrialType,3);
            epochInterFlashInt = obj.trialTypes(epochTrialType,4);
            obj.plotData.epochObjectColor = epochObjectColor;
            obj.plotData.epochObjectSize = epochObjectSize;
            obj.plotData.epochFlashDur = epochFlashDur;
            obj.plotData.epochInterFlashInt = epochInterFlashInt;
            
            % Determine object size and position in pixels
            objectPosDeg = [obj.screenOriginHorzOffsetDeg-obj.RFcenterX+obj.Xoffset,obj.RFcenterY+obj.Yoffset];
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenWidthLeftPix = obj.screenWidthLeft*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            objectEdgesXPix = screenWidthLeftPix+screenDistPix*tand([objectPosDeg(1)-epochObjectSize/2,objectPosDeg(1)+epochObjectSize/2]);
            objectEdgesYPix = screenHeightBelowPix+screenDistPix*tand([objectPosDeg(2)-epochObjectSize/2,objectPosDeg(2)+epochObjectSize/2]);
            objectSizeXPix = diff(objectEdgesXPix);
            objectSizeYPix = diff(objectEdgesYPix);
            XposPix = objectEdgesXPix(1)+objectSizeXPix/2;
            YposPix = objectEdgesYPix(1)+objectSizeYPix/2;
            
            % Create object size vector; pad with zeros to make object disappear
            % during postTime and while stop stimGL completes
            frameRate = double(GetRefreshRate(obj.stimGL));
            flashFrames = round(epochFlashDur*frameRate);
            interFlashFrames = round(epochInterFlashInt*frameRate);
            nStimFrames = obj.numFlashes*flashFrames+((obj.numFlashes-1)*interFlashFrames);
            XsizeVectorPix = zeros(1,nStimFrames);
            YsizeVectorPix = zeros(1,nStimFrames);
            for n=0:obj.numFlashes-1
                XsizeVectorPix(1+n*(flashFrames+interFlashFrames):flashFrames+n*(flashFrames+interFlashFrames)) = objectSizeXPix;
                YsizeVectorPix(1+n*(flashFrames+interFlashFrames):flashFrames+n*(flashFrames+interFlashFrames)) = objectSizeYPix;
            end
            XsizeVectorPix = [XsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            YsizeVectorPix = [YsizeVectorPix,zeros(1,(obj.postTime+10)*frameRate)];
            
            % Specify frame parameters in frame_vars.txt file
            % create frameVars matrix
            params.nFrames = numel(XsizeVectorPix);
            frameVars = zeros(params.nFrames,12);
            frameVars(:,1) = 0:params.nFrames-1; % frame number
            frameVars(:,4) = 1; % objType (ellipse=1)
            frameVars(:,5) = XposPix;
            frameVars(:,6) = YposPix;
            frameVars(:,7) = XsizeVectorPix;
            frameVars(:,8) = YsizeVectorPix;
            frameVars(:,10) = epochObjectColor;
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
            
            % Set number of delay frames for preTime and determine stimTime
            params.delay = round(obj.preTime*frameRate);
            stimTime = nStimFrames/frameRate;
            obj.plotData.stimTime = stimTime;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectColor', epochObjectColor);
            obj.addParameter('epochObjectSize', epochObjectSize);
            obj.addParameter('epochFlashDur', epochFlashDur);
            obj.addParameter('epochInterFlashInt', epochInterFlashInt);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.rigConfig.sampleRate*(obj.preTime+stimTime+obj.postTime)));
            stimulus(0.1*obj.rigConfig.sampleRate+1:0.2*obj.rigConfig.sampleRate) = 1e-12*obj.testPulseAmp;
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 1);
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
            
            % Update epoch and mean response (spike count) versus object color and/or size
            obj.plotData.time = 1/obj.rigConfig.sampleRate*(1:numel(data));
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold,1));
            if isempty(obj.plotData.stimStart) || obj.plotData.stimStart<obj.preTime
                obj.plotData.stimStart = obj.preTime;
            end
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            obj.plotData.epochResp = numel(find(spikeTimes>obj.plotData.stimStart & spikeTimes<obj.plotData.stimStart+obj.plotData.epochFlashDur));
            if numel(obj.objectColor)>1
                objectColorIndex = find(obj.objectColor==obj.plotData.epochObjectColor,1);
                obj.plotData.meanColorResp(objectColorIndex) = nanmean([repmat(obj.plotData.meanColorResp(objectColorIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
            end
            if numel(obj.objectSize)>1
                objectSizeIndex = find(obj.objectSize==obj.plotData.epochObjectSize,1);
                obj.plotData.meanSizeResp(objectSizeIndex) = nanmean([repmat(obj.plotData.meanSizeResp(objectSizeIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
            end
            if numel(obj.flashDur)>1
                flashDurIndex = find(obj.flashDur==obj.plotData.epochFlashDur,1);
                obj.plotData.meanFlashDurResp(flashDurIndex) = nanmean([repmat(obj.plotData.meanFlashDurResp(flashDurIndex),1,obj.loopCount-1),obj.plotData.epochResp]);
            end
            if obj.numFlashes>1
                if numel(obj.interFlashInt)>1
                    flash1resp = numel(find(spikeTimes>obj.plotData.stimStart & spikeTimes<obj.plotData.stimStart+obj.plotData.epochFlashDur));
                    if flash1resp==0
                        obj.plotData.epochFlashRespRatio = NaN;
                    else
                        flash2resp = numel(find(spikeTimes>obj.plotData.stimStart+obj.plotData.epochFlashDur+obj.plotData.interFlashInt & spikeTimes<obj.plotData.stimStart+2*obj.plotData.epochFlashDur+obj.plotData.interFlashInt));
                        obj.plotData.epochFlashRespRatio = flash2resp/flash1resp;
                    end
                    interFlashIntIndex = find(obj.interFlashInt==obj.plotData.epochInterFlashInt,1);
                    obj.plotData.meanInterFlashIntResp(interFlashIntIndex) = nanmean([repmat(obj.plotData.meanInterFlashIntResp(interFlashIntIndex),1,obj.loopCount-1),obj.plotData.epochFlashRespRatio]);
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
                pause(rand(1)*(obj.interTrialIntMax-obj.interTrialIntMin)+obj.interTrialIntMin);
            end
        end
        
    end
    
end