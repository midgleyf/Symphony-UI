%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Grid < StimGLProtocol

    properties (Constant)
        identifier = 'Symphony.StimGL.Grid'
        version = 1
        displayName = 'Grid'
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
        allCoords
        notCompletedCoords
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
        objectColor = 1;
        objectSize = 10;
        gridOriginX = 97.5;
        gridOriginY = -10;
        gridWidth = 80;
        gridHeight = 50;
    end
    
    properties (Dependent = true, SetAccess = private)
        Xcoords = [NaN,NaN];
        Ycoords = [NaN,NaN];
    end
    
    methods
        
        function Xcoords = get.Xcoords(obj)
            nPts = floor(obj.gridWidth/obj.objectSize);
            centerShift = 0.5*(obj.gridWidth-nPts*obj.objectSize);
            Xcoords = centerShift+obj.gridOriginX-(obj.objectSize/2:obj.objectSize:nPts*obj.objectSize-obj.objectSize/2);
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
            
            % Get all grid coordinates
            obj.allCoords = allcombs(obj.Xcoords,obj.Ycoords);
            obj.notCompletedCoords = 1:size(obj.allCoords,1);
            
            % Prepare figures
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            obj.plotData.meanOnResp = NaN(numel(obj.Ycoords),numel(obj.Xcoords));
            obj.openFigure('Custom','Name','MeanOnRespFig','UpdateCallback',@updateMeanOnRespFig);
            obj.plotData.meanOffResp = NaN(numel(obj.Ycoords),numel(obj.Xcoords));
            obj.openFigure('Custom','Name','MeanOffRespFig','UpdateCallback',@updateMeanOffRespFig);
            obj.plotData.updateOnRespFit = false;
            obj.plotData.updateOffRespFit = false;
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
            set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum-size(obj.allCoords,1)*(obj.loopCount-1)) ' of ' num2str(size(obj.allCoords,1)) ' in loop ' num2str(obj.loopCount) ' of ' num2str(obj.numberOfLoops)]);
        end
        
        function updateMeanOnRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.onRespImageHandle = imagesc(flipud(obj.plotData.meanOnResp),'Parent',axesHandle); colormap(gray(256)); colorbar; axis image;
                obj.plotData.onRFcenterHandle=line(0,0,'Marker','x','Color','g');
                obj.plotData.onRFareaHandle=line(0,0,'Color','g');
                set(axesHandle,'Box','off','TickDir','out','XTick',1:numel(obj.Xcoords),'XTickLabel',obj.Xcoords,'YTick',1:numel(obj.Ycoords),'YTickLabel',fliplr(obj.Ycoords));
                xlabel(axesHandle,'azimuth (degrees)');
                ylabel(axesHandle,'elevation (degrees)');
                title(axesHandle,'On response (spike count)');
                obj.plotData.updateFitCheckboxHandle = uicontrol(get(axesHandle,'Parent'),'Style','checkbox','Units','normalized','Position',[0 0 0.15 0.05],'Value',0,'String','update fit');
            else
                set(obj.plotData.onRespImageHandle,'Cdata',flipud(obj.plotData.meanOnResp));
                if obj.plotData.updateOnRespFit
                    set(obj.plotData.onRFcenterHandle,'XData',obj.plotData.muXon,'YData',obj.plotData.muYon);
                    [X Y]=calcEllipse(obj.plotData.muXon,obj.plotData.muYon,obj.plotData.sigmaXon,obj.plotData.sigmaYon,obj.plotData.onRotation);
                    set(obj.plotData.onRFareaHandle,'XData',X,'YData',Y);
                    title(axesHandle,['On response (spike count), ' obj.plotData.onRFstring]);
                end
            end
        end
        
        function updateMeanOffRespFig(obj,axesHandle)
            if obj.epochNum==1
                obj.plotData.offRespImageHandle = imagesc(flipud(obj.plotData.meanOffResp),'Parent',axesHandle); colormap(gray(256)); colorbar; axis image;
                obj.plotData.offRFcenterHandle=line(0,0,'Marker','x','Color','r');
                obj.plotData.offRFareaHandle=line(0,0,'Color','r');
                set(axesHandle,'Box','off','TickDir','out','XTick',1:numel(obj.Xcoords),'XTickLabel',obj.Xcoords,'YTick',1:numel(obj.Ycoords),'YTickLabel',fliplr(obj.Ycoords));
                xlabel(axesHandle,'azimuth (degrees)');
                ylabel(axesHandle,'elevation (degrees)');
                title(axesHandle,'Off response (spike count)');
            else
                set(obj.plotData.offRespImageHandle,'Cdata',flipud(obj.plotData.meanOffResp));
                if obj.plotData.updateOffRespFit
                    set(obj.plotData.offRFcenterHandle,'XData',obj.plotData.muXoff,'YData',obj.plotData.muYoff);
                    [X Y]=calcEllipse(obj.plotData.muXoff,obj.plotData.muYoff,obj.plotData.sigmaXoff,obj.plotData.sigmaYoff,obj.plotData.offRotation);
                    set(obj.plotData.offRFareaHandle,'XData',X,'YData',Y);
                    title(axesHandle,['Off response (spike count), ' obj.plotData.offRFstring]);
                end
            end
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
            screenWidthLeftPix = obj.screenWidthLeft*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            objectEdgesXPix = screenWidthLeftPix+screenDistPix*tand([obj.screenOriginHorzOffsetDeg-stimPosX-obj.objectSize/2,obj.screenOriginHorzOffsetDeg-stimPosX+obj.objectSize/2]);
            objectEdgesYPix = screenHeightBelowPix+screenDistPix*tand([stimPosY-obj.objectSize/2,stimPosY+obj.objectSize/2]); 
            objectSizeXPix = diff(objectEdgesXPix);
            objectSizeYPix = diff(objectEdgesYPix);
            params.objXinit = objectEdgesXPix(1)+objectSizeXPix/2;
            params.objYinit = objectEdgesYPix(1)+objectSizeYPix/2;
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = round((obj.stimglDelay+obj.preTime)*frameRate);
            params.nFrames = round(obj.stimTime*frameRate);
            params.tFrames = params.nFrames;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime and while stop stimGL completes
            params.objLenX = [objectSizeXPix zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            params.objLenY = [objectSizeYPix zeros(1,ceil((obj.postTime+10)/obj.stimTime))];
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('stimPosX',stimPosX);
            obj.addParameter('stimPosY',stimPosY);
            
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
            
            % Update mean responses (spike count)
            obj.plotData.time = 1/obj.rigConfig.sampleRate*(1:numel(data));
            obj.plotData.stimStart = obj.plotData.time(find(obj.response('Photodiode')>=obj.photodiodeThreshold,1));
            if isempty(obj.plotData.stimStart)
                obj.plotData.stimStart = obj.preTime;
            end
            spikeTimes = obj.plotData.time(obj.plotData.spikePts);
            onResp = numel(find(spikeTimes>obj.plotData.stimStart & spikeTimes<obj.plotData.stimStart+obj.stimTime));
            offResp = numel(find(spikeTimes>obj.plotData.stimStart+obj.stimTime & spikeTimes<obj.plotData.stimStart+2*obj.stimTime));
            Yindex = find(obj.Ycoords==obj.plotData.stimPosY,1);
            Xindex = find(obj.Xcoords==obj.plotData.stimPosX,1);
            if obj.loopCount==1
                obj.plotData.meanOnResp(Yindex,Xindex) = onResp;
                obj.plotData.meanOffResp(Yindex,Xindex) = offResp;
            else
                obj.plotData.meanOnResp(Yindex,Xindex) = mean([repmat(obj.plotData.meanOnResp(Yindex,Xindex),1,obj.loopCount-1),onResp]);
                obj.plotData.meanOffResp(Yindex,Xindex) = mean([repmat(obj.plotData.meanOffResp(Yindex,Xindex),1,obj.loopCount-1),offResp]);
            end
            
            % Fit on and off response grids to 2D guassian to find RF center and sd
            if obj.epochNum>1
                if get(obj.plotData.updateFitCheckboxHandle,'Value')
                    try
                        [obj.plotData.onRFstring obj.plotData.muXon obj.plotData.muYon obj.plotData.sigmaXon obj.plotData.sigmaYon obj.plotData.onRotation]=gauss2Dfit(obj.Xcoords,obj.Ycoords,obj.plotData.meanOnResp);
                        obj.plotData.updateOnRespFit = true;
                    catch
                        obj.plotData.updateOnRespFit = false;
                    end
                    try
                        [obj.plotData.offRFstring obj.plotData.muXoff obj.plotData.muYoff obj.plotData.sigmaXoff obj.plotData.sigmaYoff obj.plotData.offRotation]=gauss2Dfit(obj.Xcoords,obj.Ycoords,obj.plotData.meanOffResp);
                        obj.plotData.updateOffRespFit = true;
                    catch
                        obj.plotData.updateOffRespFit = false;
                    end
                    set(obj.plotData.updateFitCheckboxHandle,'Value',0);
                else
                    obj.plotData.updateOnRespFit = false;
                    obj.plotData.updateOffRespFit = false;
                end
            end
            
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % if all grid coordinates completed, reset completedCoords and start a new loop
            if isempty(obj.notCompletedCoords)
                obj.notCompletedCoords = 1:size(obj.allCoords,1);
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