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
        threshLimitReturn = [0,100,0];
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
        Xcoords;
        Ycoords;
    end
    
    methods
        
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
            obj.plotData.spikePts = [];
            obj.plotData.meanOnResp = zeros(numel(obj.Ycoords),numel(obj.Xcoords));
            obj.plotData.meanOffResp = zeros(numel(obj.Ycoords),numel(obj.Xcoords));
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            obj.openFigure('Custom','Name','MeanOnRespFig','UpdateCallback',@updateMeanOnRespFig);
            obj.openFigure('Custom','Name','MeanOffRespFig','UpdateCallback',@updateMeanOffRespFig);
        end
        
        function updateResponseFig(obj,axesHandle)
            %sampInt=1/10000*1000;
            %t=sampInt:sampInt:sampInt*double(obj.prePts+obj.stimPts+obj.postPts);
            data = obj.response;
            plot(axesHandle,data,'k');
            hold on;
            plot(axesHandle,obj.plotData.spikePts,data(obj.plotData.spikePts),'go');
            hold off;
            xlabel(axesHandle,'ms');
            ylabel(axesHandle,'mV');
            set(axesHandle,'TickDir','out','Box','off');
            if obj.epochNum==1
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.225 0.96 0.075 0.03],'String','thresh');
                obj.plotData.threshEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.31 0.95 0.075 0.05],'String',num2str(obj.threshLimitReturn(1)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.45 0.96 0.075 0.03],'String','limit');
                obj.plotData.limitEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.535 0.95 0.075 0.05],'String',num2str(obj.threshLimitReturn(2)));
                uicontrol(get(axesHandle,'Parent'),'Style','text','Units','normalized','Position',[0.675 0.96 0.075 0.03],'String','return');
                obj.plotData.returnEditHandle = uicontrol(get(axesHandle,'Parent'),'Style','edit','Units','normalized','Position',[0.76 0.95 0.075 0.05],'String',num2str(obj.threshLimitReturn(3)));
            end
        end
        
        function updateMeanOnRespFig(obj,axesHandle)
            imagesc(obj.plotData.meanOnResp,'Parent',axesHandle); colorbar;
            set(axesHandle,'TickDir','out','XTick',1:numel(obj.Xcoords),'XTickLabel',obj.Xcoords,'YTick',1:numel(obj.Ycoords),'YTickLabel',obj.Ycoords);
        end
        
        function updateMeanOffRespFig(obj,axesHandle)
            imagesc(obj.plotData.meanOffResp,'Parent',axesHandle); colorbar;
            set(axesHandle,'TickDir','out','XTick',1:numel(obj.Xcoords),'XTickLabel',obj.Xcoords,'YTick',1:numel(obj.Ycoords),'YTickLabel',obj.Ycoords);
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
            epochCoord = obj.allCoords(obj.notCompletedCoords(randIndex),:);
            obj.notCompletedCoords(randIndex) = [];
            
            % Set object properties
            params.numObj = 1;
            params.objColor = obj.objectColor;
            params.objType = 'box';
            % get object position and size in pixels
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            objectEdgesXPix = obj.xMonPix/2+screenDistPix*tand([epochCoord(1)-obj.objectSize/2,epochCoord(1)+obj.objectSize/2]);
            objectEdgesYPix = screenHeightBelowPix+screenDistPix*tand([epochCoord(2)-obj.objectSize/2,epochCoord(2)+obj.objectSize/2]); 
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
            params.objLenX = [objectSizeXPix zeros(1,ceil((obj.postTime+1)/obj.stimTime))];
            params.objLenY = [objectSizeYPix zeros(1,ceil((obj.postTime+1)/obj.stimTime))];
            
            % Add epoch-specific parameters for ovation
            % convert stimCoords back to degrees
            obj.addParameter('stimPosX', epochCoord(1));
            obj.addParameter('stimPosY', epochCoord(2));
            
            % Create a dummy stimulus so the epoch runs for the desired length
            sampleRate = 1000;
            stimulus = zeros(1, floor(sampleRate*(obj.preTime+obj.stimTime+obj.postTime)));
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 1);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
            % Find spikes
            data=obj.response;
            if obj.epochNum==1
                threshold = obj.threshLimitReturn(1);
                limitThresh = obj.threshLimitReturn(2);
                returnThresh = obj.threshLimitReturn(3);
            else
                threshold = str2double(get(obj.plotData.threshEditHandle,'String'));
                limitThresh = str2double(get(obj.plotData.limitEditHandle,'String'));
                returnThresh = str2double(get(obj.plotData.returnEditHandle,'String'));
            end
            % flip data and threshold if negative-going spike peaks
            if false%~handles.posSpikePolarity
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
                if isnan(limitThresh) || peak<limitThresh
                    obj.plotData.spikePts(end+1)=posThreshCross-1+peakIndex;
                end
                posThreshCross=negThreshCross+find(data(negThreshCross+1:end)>=threshold,1);
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