classdef ExpandingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Expanding Objects'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        screenDist = 12.8;
        screenWidth = 22.4;
        screenHeight = 12.6;
        screenHeightBelow = 3.3;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
    end

    properties
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        intertrialIntervalMin = 1;
        intertrialIntervalMax = 2;
        backgroundColor = 0;
        %numObjects = {'1','2'};
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
        
        %function set.numObjects(obj,numObjects)
        %    obj.numObjects = str2double(numObjects);
        %end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get all combinations of trial types based on object expansion speed if numObjects is one
            % or object expansion speeds and object2 position if numObjects is two
            if obj.numObjects==1
                obj.trialTypes = obj.objectExpansionRate';
            elseif obj.numObjects==2
                obj.trialTypes=allcombs(obj.objectExpansionRate,obj.object2PositionX,obj.object2PositionY,obj.object2ExpansionRate);
            end
            obj.notCompletedTrialTypes=1:size(obj.trialTypes,1);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            params.numObj = obj.numObjects;
            
            % Pick a combination of object speeds and object2 position from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectExpansionRate = obj.trialTypes(epochTrialType,1);
            if obj.numObjects==2
                epochObject2PositionX = obj.trialTypes(epochTrialType,2);
                epochObject2PositionY = obj.trialTypes(epochTrialType,3);
                epochObject2ExpansionRate = obj.trialTypes(epochTrialType,4);
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
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            leftEdgesPix = 0.5*obj.xMonPix+screenDistPix*tand(obj.objectPositionX-0.5*sizeVectorDeg);
            rightEdgesPix = 0.5*obj.xMonPix+screenDistPix*tand(obj.objectPositionX+0.5*sizeVectorDeg);
            bottomEdgesPix = screenHeightBelowPix+screenDistPix*tand(obj.objectPositionY-0.5*sizeVectorDeg);
            topEdgesPix = screenHeightBelowPix+screenDistPix*tand(obj.objectPositionY+0.5*sizeVectorDeg);
            XsizeVectorPix = rightEdgesPix-leftEdgesPix;
            YsizeVectorPix = topEdgesPix-bottomEdgesPix;
            XposVectorPix = leftEdgesPix+0.5*XsizeVectorPix;
            YposVectorPix = bottomEdgesPix+0.5*YsizeVectorPix;
            XsizeVectorPix =[XsizeVectorPix,zeros(1,(obj.postTime+1)*frameRate)];
            YsizeVectorPix =[YsizeVectorPix,zeros(1,(obj.postTime+1)*frameRate)];
            if obj.numObjects==2
                leftEdgesPix = 0.5*obj.xMonPix+screenDistPix*tand(obj.object2PositionX-0.5*sizeVectorDeg2);
                rightEdgesPix = 0.5*obj.xMonPix+screenDistPix*tand(obj.object2PositionX+0.5*sizeVectorDeg2);
                bottomEdgesPix = screenHeightBelowPix+screenDistPix*tand(obj.object2PositionY-0.5*sizeVectorDeg2);
                topEdgesPix = screenHeightBelowPix+screenDistPix*tand(obj.object2PositionY+0.5*sizeVectorDeg2);
                XsizeVectorPix2 = rightEdgesPix-leftEdgesPix;
                YsizeVectorPix2 = topEdgesPix-bottomEdgesPix;
                XposVectorPix2 = leftEdgesPix+0.5*XsizeVectorPix2;
                YposVectorPix2 = bottomEdgesPix+0.5*YsizeVectorPix2;
                XsizeVectorPix2 =[XsizeVectorPix2,zeros(1,(obj.postTime+1)*frameRate)];
                YsizeVectorPix2 =[YsizeVectorPix2,zeros(1,(obj.postTime+1)*frameRate)];
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
            params.delay = round(obj.preTime*frameRate);
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjectExpansionRate',epochObjectExpansionRate);
            if obj.numObjects==2
                obj.addParameter('epochObject2PositionX',epochObject2PositionX);
                obj.addParameter('epochObject2PositionY',epochObject2PositionY);
                obj.addParameter('epochObject2ExpansionRate',epochObject2ExpansionRate);
            end
            
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