classdef Grid < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Grid'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        screenDist = 12.8;
        screenWidth = 22.4;
        screenHeight = 12.6;
        screenHeightBelow = 3.3;
    end
    
    properties (Hidden)
        allCoords
        notCompletedCoords
        plotData
    end

    properties
        spikePolThrLimRet = [Inf,0,100,0];
        samplingRate = 50000;
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        intertrialIntervalMin = 1;
        intertrialIntervalMax = 2;
        backgroundColor = 0;
        objectColor = 1;
        objectSize = 10;
        gridOriginX = -40.5;
        gridOriginY = -14;
        gridWidth = 81;
        gridHeight = 49.5;
    end
    
    properties (Dependent = true, SetAccess = private)
        Xcoords = [NaN,NaN];
        Ycoords = [NaN,NaN];
    end
    
    methods
        
        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
            % TODO: remove this once the base class is handling the sample rate
            obj.rigConfig.sampleRate = obj.samplingRate;
        end
        
        function Xcoords = get.Xcoords(obj)
            nPts = floor(obj.gridWidth/obj.objectSize);
            centerShift = 0.5*(obj.gridWidth-nPts*obj.objectSize);
            Xcoords = centerShift+obj.gridOriginX+(obj.objectSize/2:obj.objectSize:nPts*obj.objectSize-obj.objectSize/2);
        end
        
        function Ycoords = get.Ycoords(obj)
            nPts = floor(obj.gridHeight/obj.objectSize);
            centerShift = 0.5*(obj.gridHeight-nPts*obj.objectSize);
            Ycoords = centerShift+obj.gridOriginY+(obj.objectSize/2:obj.objectSize:nPts*obj.objectSize-obj.objectSize/2);
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            obj.allCoords = allcombs(obj.Xcoords,obj.Ycoords);
            allcombs(obj.Xcoords,obj.Ycoords);
            obj.notCompletedCoords = 1:size(obj.allCoords,1);
            
            % Prepare figures
            sampInt = 1/obj.samplingRate;
            obj.plotData.time = sampInt:sampInt:obj.preTime+obj.stimTime+obj.postTime;
            obj.plotData.meanOnResp = zeros(numel(obj.Ycoords),numel(obj.Xcoords));
            obj.plotData.meanOffResp = zeros(numel(obj.Ycoords),numel(obj.Xcoords));
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            obj.openFigure('Custom','Name','MeanOnRespFig','UpdateCallback',@updateMeanOnRespFig);
            obj.openFigure('Custom','Name','MeanOffRespFig','UpdateCallback',@updateMeanOffRespFig);
        end
        
        function updateResponseFig(obj,axesHandle)
            data = obj.response('Amplifier_Ch1');
            plot(axesHandle,obj.plotData.time,data,'k');
            hold on;
            plot(axesHandle,obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'go');
            hold off;
            xlabel(axesHandle,'s');
            ylabel(axesHandle,'mV');
            set(axesHandle,'Box','off','TickDir','out');
            if obj.epochNum==1
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.18 0.96 0.075 0.03],'String','polarity');
                obj.plotData.polarityEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.265 0.95 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(1)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.36 0.96 0.075 0.03],'String','thresh');
                obj.plotData.threshEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.445 0.95 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(2)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.54 0.96 0.075 0.03],'String','limit');
                obj.plotData.limitEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.625 0.95 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(3)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.72 0.96 0.075 0.03],'String','return');
                obj.plotData.returnEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.805 0.95 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(4)));
            end
        end
        
        function updateMeanOnRespFig(obj,axesHandle)
            imagesc(flipud(obj.plotData.meanOnResp),'Parent',axesHandle); colorbar; axis image;
            set(axesHandle,'Box','off','TickDir','out','XTick',1:numel(obj.Xcoords),'XTickLabel',obj.Xcoords,'YTick',1:numel(obj.Ycoords),'YTickLabel',fliplr(obj.Ycoords));
            xlabel('azimuth (degrees)');
            ylabel('elevation (degrees)');
            title('On response (spike count)');
        end
        
        function updateMeanOffRespFig(obj,axesHandle)
            imagesc(flipud(obj.plotData.meanOffResp),'Parent',axesHandle); colorbar; axis image;
            set(axesHandle,'Box','off','TickDir','out','XTick',1:numel(obj.Xcoords),'XTickLabel',obj.Xcoords,'YTick',1:numel(obj.Ycoords),'YTickLabel',fliplr(obj.Ycoords));
            xlabel('azimuth (degrees)');
            ylabel('elevation (degrees)');
            title('Off response (spike count)');
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Pick a random grid point; complete all grid points before repeating any
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedCoords),1);
            stimPosX = obj.allCoords(obj.notCompletedCoords(randIndex),1);
            stimPosY = obj.allCoords(obj.notCompletedCoords(randIndex),2);
            obj.notCompletedCoords(randIndex) = [];
            obj.plotData.stimPosX = stimPosX;
            obj.plotData.stimPosY = stimPosY;
            
            % Set object properties
            params.numObj = 1;
            params.objColor = obj.objectColor;
            params.objType = 'box';
            % get object position and size in pixels
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            objectEdgesXPix = obj.xMonPix/2+screenDistPix*tand([stimPosX-obj.objectSize/2,stimPosX+obj.objectSize/2]);
            objectEdgesYPix = screenHeightBelowPix+screenDistPix*tand([stimPosY-obj.objectSize/2,stimPosY+obj.objectSize/2]); 
            objectSizeXPix = diff(objectEdgesXPix);
            objectSizeYPix = diff(objectEdgesYPix);
            params.objXinit = objectEdgesXPix(1)+objectSizeXPix/2;
            params.objYinit = objectEdgesYPix(1)+objectSizeYPix/2;
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = obj.preTime*frameRate;
            params.nFrames = round(obj.stimTime*frameRate);
            params.tFrames = params.nFrames;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            params.objLenX = [objectSizeXPix zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            params.objLenY = [objectSizeYPix zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            
            % Add epoch-specific parameters for ovation
            % convert stimCoords back to degrees
            obj.addParameter('stimPosX',stimPosX);
            obj.addParameter('stimPosY',stimPosY);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.samplingRate*(obj.preTime+obj.stimTime+obj.postTime)));
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
            
            % Update mean responses (spike count)
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            onResp = numel(find(spikeTimes>obj.preTime & spikeTimes<obj.preTime+obj.stimTime));
            offResp = numel(find(spikeTimes>obj.preTime+obj.stimTime & spikeTimes<obj.preTime+2*obj.stimTime));
            if obj.loopCount==1
                obj.plotData.meanOnResp(obj.Ycoords==obj.plotData.stimPosY,obj.Xcoords==obj.plotData.stimPosX) = onResp;
                obj.plotData.meanOffResp(obj.Ycoords==obj.plotData.stimPosY,obj.Xcoords==obj.plotData.stimPosX) = offResp;
            else
                obj.plotData.meanOnResp(obj.Ycoords==obj.plotData.stimPosY,obj.Xcoords==obj.plotData.stimPosX) = mean([repmat(obj.plotData.meanOnResp,1,obj.loopCount-1),onResp]);
                obj.plotData.meanOffResp(obj.Ycoords==obj.plotData.stimPosY,obj.Xcoords==obj.plotData.stimPosX) = mean([repmat(obj.plotData.meanOnResp,1,obj.loopCount-1),offResp]);
            end
            
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % if all grid coordinates completed, reset completedCoords and start a new loop
            if isempty(obj.notCompletedCoords)
                obj.notCompletedCoords = obj.allCoords;
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