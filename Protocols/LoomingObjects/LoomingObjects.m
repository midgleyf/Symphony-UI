classdef LoomingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Looming Objects'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
        screenDist = 12.8;
        screenWidth = 22.4;
        screenHeightAbove = 9.3;
        screenHeightBelow = 3.3;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
    end

    properties
        preTime = 0.5;
        postTime = 0.5;
        interTrialInterval = [1 2];
        backgroundColor = 0;
        %numObjects = {'1','2'};
        numObjects = 1;
        objColor = 1;
        objPositionX = 150;
        objPositionY = 300;
        objSize = 5;
        objSpeed = 10000;
        thetaMin = 0.5;
        thetaMax = 20;
        holdTime = 0.1;
        obj2Color = 1;
        obj2PositionX = 650;
        obj2PositionY = 300;
        relCollisionTime = [-0.1,0.1,Inf];
    end
    
    
    methods
        
        
        %function set.numObjects(obj,numObjects)
        %   obj.numObjects = str2double(numObjects);
        %end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get all combinations of trial types based on object colors,
            % positions, start sizes, and loom speeds
            if obj.numObjects==1
                obj.trialTypes=allcombs(obj.objColor,obj.objPositionX,obj.objPositionY,obj.objSpeed);
            elseif obj.numObjects==2
                obj.trialTypes=allcombs(obj.objColor,obj.objPositionX,obj.objPositionY,obj.objSpeed,obj.obj2Color,obj.obj2PositionX,obj.obj2PositionY,obj.relCollisionTime);
            end
            obj.notCompletedTrialTypes=1:size(obj.trialTypes,1);
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
            params.ftrack_change = 2;
            
            % Set object properties
            params.numObj = obj.numObjects;
            % pick a combination of object color/position/size/speed from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            params.objType = 'ellipse';
            params.objColor = obj.trialTypes(epochTrialType,1);
            params.objXinit = obj.trialTypes(epochTrialType,2);
            params.objYinit = obj.trialTypes(epochTrialType,3);
            epochObjSpeed = obj.trialTypes(epochTrialType,4);
            if obj.numObjects==2
                params.objType2 = 'ellipse';
                params.objColor2 = obj.trialTypes(epochTrialType,5);
                params.objXinit2 = obj.trialTypes(epochTrialType,6);
                params.objYinit2 = obj.trialTypes(epochTrialType,7);
                epochRelCollisionTime = obj.trialTypes(epochTrialType,8);
            end
            
            % Set the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = round(obj.preTime*frameRate);
            
            % Calculate length vectors and pad with zeros to make object disappear
            % during postTime plus plenty of extra time to complete stop stimGL
            params.tFrames =1;
            objHalfSize = obj.screenDist*tand(obj.objSize/2);
            LoverV = objHalfSize/-epochObjSpeed*frameRate;
            theta = 2*atand(LoverV./(-frameRate*10:-1));
            theta = theta(theta>=obj.thetaMin);
            theta(theta>obj.thetaMax) = obj.thetaMax;
            theta = [theta,obj.thetaMax*ones(1,round(obj.holdTime*frameRate))];
            sizeVector = round(2*obj.screenDist*tand(theta/2));
            if obj.numObjects==2
                frameShift = round(abs(epochRelCollisionTime)*frameRate);
                if isinf(epochRelCollisionTime)
                    sizeVector2 = 2*objHalfSize*ones(1,numel(sizeVector));
                elseif epochRelCollisionTime>=0
                    sizeVector2 = [ones(1,frameShift),sizeVector(1:end-frameShift)];
                else
                    sizeVector2 = [sizeVector(frameShift+1:end),max(sizeVector)*ones(1,frameShift)];
                end
            end
            params.nFrames = numel(sizeVector);
            stimTime = params.nFrames/frameRate;
            params.objLenX = [sizeVector zeros(1,ceil((obj.postTime+stimTime+10)/(params.tFrames/frameRate)))];
            params.objLenY = params.objLenX;
            if obj.numObjects==2
                params.objLenX2 = [sizeVector2 zeros(1,ceil((obj.postTime+stimTime+10)/(params.tFrames/frameRate)))];
                params.objLenY2 = params.objLenX2;
            end
                       
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjColor',params.objColor);
            obj.addParameter('epochObjPosX',params.objXinit);
            obj.addParameter('epochObjPosY',params.objYinit);
            obj.addParameter('epochObjSpeed',epochObjSpeed);
            if obj.numObjects==2
                obj.addParameter('epochObj2Color',params.objColor2);
                obj.addParameter('epochObj2PosX',params.objXinit2);
                obj.addParameter('epochObj2PosY',params.objYinit2);
                obj.addParameter('epochRelCollisionTime',epochRelCollisionTime);
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
                obj.notCompletedTrialTypes = obj.trialTypes;
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