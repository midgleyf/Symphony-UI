classdef LoomingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Looming Objects'
        plugInName = 'MovingObjects'
        xMonPix = 800;
        yMonPix = 600;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
    end

    properties
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        interTrialInterval = [1 2];
        backgroundColor = 0;
        numObjects = {'1','2'};
        obj1Color = 1;
        obj1PositionX = 200;
        obj1PositionY = 300;
        obj1StartSize = 3;
        obj1LoomSpeed = 30;
        obj2Color = 1;
        obj2PositionX = 600;
        obj2PositionY = 300;
        obj2StartSize = 3;
        obj2LoomSpeed = 30;
    end
    
    
    methods
        
        function set.numObjects(obj,numObjects)
            obj.numObjects = str2double(numObjects);
        end
        
        function prepareRun(obj)
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get all combinations of trial types based on object colors,
            % positions, start sizes, and loom speeds
            if obj.numObjects==1
                obj.trialTypes=allcombs(obj.obj1Color,obj.obj1PositionX,obj.obj1PositionY,obj.obj1StartSize,obj.obj1LoomSpeed);
            elseif obj.numObjects==2
                obj.trialTypes=allcombs(obj.obj1Color,obj.obj1PositionX,obj.obj1PositionY,obj.obj1StartSize,obj.obj1LoomSpeed,obj.obj2Color,obj.obj2PostionX,obj.obj2PositionY,obj.obj2StartSize,obj.obj2LoomSpeed);
            end
            obj.notCompletedTrialTypes=1:size(obj.trialTypes,1);
        end
        
        function prepareEpoch(obj)
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.nLoops = 0;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
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
            startSize1 = obj.trialTypes(epochTrialType,4);
            loomSpeed1 = obj.trialTypes(epochTrialType,5);
            if obj.numObjects==2
                params.objType2 = 'ellipse';
                params.objColor2 = obj.trialTypes(epochTrialType,6);
                params.objXinit2 = obj.trialTypes(epochTrialType,7);
                params.objYinit2 = obj.trialTypes(epochTrialType,8);
                startSize2 = obj.trialTypes(epochTrialType,9);
                loomSpeed2 = obj.trialTypes(epochTrialType,10);
            end
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = obj.preTime*frameRate;
            params.nFrames = round(obj.stimTime*frameRate);
            
            % Calculate tFrames and object length vectors
            % Pad length vectors with zeros to make object disappear
            % during postTime plus plenty of extra time to complete stop stimGL
            params.tFrames = frameRate/loomSpeed1;
            sizeVector = startSize1+(1:round(params.nFrames/params.tFrames));
            params.objLenX = [sizeVector zeros(1,ceil((obj.postTime+obj.stimTime+10)/(params.tFrames/frameRate)))];
            params.objLenY = params.objLenX;
            % TODO: object2
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObj1Color',params.objColor);
            obj.addParameter('epochObj1Position',[params.objXinit,params.objYinit]);
            obj.addParameter('epochObj1StartSize',startSize1);
            obj.addParameter('epochObj1LoomSpeed',loomSpeed1);
            if obj.numObjects==2
                obj.addParameter('epochObj1Color',params.objColor1);
                obj.addParameter('epochObj1Position',[params.objXinit1,params.objYinit2]);
                obj.addParameter('epochObj1StartSize',startSize1);
                obj.addParameter('epochObj1LoomSpeed',loomSpeed1);
            end
            
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
            % if all stim sizes completed, reset notCompeletedSizes and start a new loop
            if isempty(obj.notCompletedTrialTypes)
                obj.notCompletedTrialTypes = obj.trialTypes;
                obj.loopCount = obj.loopCount+1;
            end
        end
        
        function keepGoing = continueRun(obj)
            if obj.numberOfLoops == 0
                % the user must stop the protocol from running
                keepGoing = true;
            else
                keepGoing = obj.loopCount <= obj.numberOfLoops;
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
        end
        
    end
    
end