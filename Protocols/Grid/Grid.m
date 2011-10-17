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
    end

    properties
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        intertrialInterval = [1,2];
        backgroundColor = 0;
        objectColor = 1;
        objectSize = 10;
        gridOrigin = [-40,-14.25];
        gridWidth = 80;
        gridHeight = 50;
    end
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get grid x and y coordinates in degrees
            nXpts = floor(obj.gridWidth/obj.objectSize);
            nYpts = floor(obj.gridHeight/obj.objectSize);
            % shift grid towards center of screen if it does not fill screen
            centerShiftX = 0.5*(obj.gridWidth-nXpts*obj.objectSize);
            centerShiftY = 0.5*(obj.gridHeight-nYpts*obj.objectSize);
            Xcoords = centerShiftX+obj.gridOrigin(1)+(obj.objectSize/2:obj.objectSize:nXpts*obj.objectSize-obj.objectSize/2);
            Ycoords = centerShiftY+obj.gridOrigin(2)+(obj.objectSize/2:obj.objectSize:nYpts*obj.objectSize-obj.objectSize/2);
            obj.allCoords = allcombs(Xcoords,Ycoords);
            obj.notCompletedCoords = 1:size(obj.allCoords,1);
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
                pause on
                if numel(obj.intertrialInterval)==1
                    pause(obj.intertrialInterval);
                else
                    pause(rand(1)*diff(obj.intertrialInterval)+obj.intertrialInterval(1));
                end
            end
        end
       
        function completeRun(obj)
            Stop(obj.stimGL);
            
            % Call the base class method.
            completeRun@SymphonyProtocol(obj);
        end
        
    end
    
end