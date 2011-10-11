classdef Grid < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Moving Objects'
        plugInName = 'MovingObjects'
        xMonPix = 800;
        yMonPix = 600;
    end
    
    properties (Hidden)
        allCoords
        notCompletedCoords
    end

    properties
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        interTrialInterval = [1 2];
        backgroundColor = 0;
        stimColor = 1;
        stimSize = 20;
        gridOrigin = [0 0];
        gridWidth = 800;
        gridHeight = 600;
    end
    
    methods
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get grid x and y coordinates
            % shrink grid if does not fit on screen
            if obj.gridOrigin(1)+obj.gridWidth>obj.xMonPix
                obj.gridWidth = obj.xMonPix-obj.gridOrigin(1);
            end
            if obj.gridOrigin(2)+obj.gridHeight>obj.yMonPix
                obj.gridHeight = obj.yMonPix-obj.gridOrigin(2);
            end
            % force stimSize to even number because stim object centers defined by stimSize/2
            obj.stimSize = 2*(round(obj.stimSize/2));
            nXpts = floor(obj.gridWidth/obj.stimSize);
            nYpts = floor(obj.gridHeight/obj.stimSize);
            % shift grid towards center of screen if it does not fill screen
            centerShiftX = round((obj.gridWidth-nXpts*obj.stimSize)/2);
            centerShiftY = round((obj.gridHeight-nYpts*obj.stimSize)/2);
            Xcoords = centerShiftX+obj.gridOrigin(1)+(obj.stimSize/2:obj.stimSize:nXpts*obj.stimSize-obj.stimSize/2);
            Ycoords = centerShiftY+obj.gridOrigin(2)+(obj.stimSize/2:obj.stimSize:nYpts*obj.stimSize-obj.stimSize/2);
            obj.allCoords = allcombs(Xcoords,Ycoords);
            obj.notCompletedCoords = 1:size(obj.allCoords,1);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.nLoops = 0;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Set object properties
            params.numObj = 1;
            params.objColor = obj.stimColor;
            params.objType = 'box';
            % pick a random grid point; complete all grid points before repeating any
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedCoords),1);
            stimCoord = obj.allCoords(obj.notCompletedCoords(randIndex),:);
            obj.notCompletedCoords(randIndex) = [];
            params.objXinit = stimCoord(1);
            params.objYinit = stimCoord(2);
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = obj.preTime*frameRate;
            params.nFrames = round(obj.stimTime*frameRate);
            params.tFrames = params.nFrames;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime plus plenty of extra time to complete stop stimGL
            params.objLenX = [obj.stimSize zeros(1,ceil((obj.postTime+obj.stimTime+10)/obj.stimTime))];
            params.objLenY = params.objLenX;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('stimCoord', stimCoord);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            sampleRate = obj.deviceSampleRate('test-device', 'OUT');
            stimulus = zeros(1, floor(sampleRate.Quantity*(obj.preTime+obj.stimTime+obj.postTime)));
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
                if numel(obj.interTrialInterval)==1
                    pause(obj.interTrialInterval);
                else
                    pause(rand(1)*diff(obj.interTrialInterval)+obj.interTrialInterval(1));
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