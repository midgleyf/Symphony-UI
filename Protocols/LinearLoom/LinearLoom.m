classdef LinearLoom < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Linear Loom'
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
        %numObjects = {'1','2'};
        numObjects = 1;
        objColor = 1;
        objPositionX = 200;
        objPositionY = 300;
        objStartSize = 3;
        objLoomSpeed = 30;
        obj2Color = 1;
        obj2PositionX = 600;
        obj2PositionY = 300;
        obj2StartSize = 3;
        obj2LoomSpeed = 20:10:40;
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
            
            % Get all combinations of trial types based on object colors,
            % positions, start sizes, and loom speeds
            if obj.numObjects==1
                obj.trialTypes=allcombs(obj.objColor,obj.objPositionX,obj.objPositionY,obj.objStartSize,obj.objLoomSpeed);
            elseif obj.numObjects==2
                obj.trialTypes=allcombs(obj.objColor,obj.objPositionX,obj.objPositionY,obj.objStartSize,obj.objLoomSpeed,obj.obj2Color,obj.obj2PositionX,obj.obj2PositionY,obj.obj2StartSize,obj.obj2LoomSpeed);
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
            startSize = obj.trialTypes(epochTrialType,4);
            loomSpeed = obj.trialTypes(epochTrialType,5);
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
            
            % Calculate length vectors and pad with zeros to make object disappear
            % during postTime plus plenty of extra time to complete stop stimGL
            params.tFrames =1;
            changeFrame = round(frameRate/loomSpeed);
            nChanges = round(params.nFrames/changeFrame);
            sizeVector = startSize+(0:nChanges);
            sizeVector = round(interp1(0:changeFrame:changeFrame*nChanges,sizeVector,1:changeFrame*nChanges,'linear'));
            params.objLenX = [sizeVector zeros(1,ceil((obj.postTime+obj.stimTime+10)/(params.tFrames/frameRate)))];
            params.objLenY = params.objLenX;
            if obj.numObjects==2
                changeFrame = round(frameRate/loomSpeed2);
                nChanges = round(params.nFrames/changeFrame);
                sizeVector = startSize2+(0:nChanges);
                sizeVector = round(interp1(0:changeFrame:changeFrame*nChanges,sizeVector,1:changeFrame*nChanges,'linear'));
                params.objLenX2 = [sizeVector zeros(1,ceil((obj.postTime+obj.stimTime+10)/(params.tFrames/frameRate)))];
                params.objLenY2 = params.objLenX2;
            end
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochObjColor',params.objColor);
            obj.addParameter('epochObjPosition',[params.objXinit,params.objYinit]);
            obj.addParameter('epochObjStartSize',startSize);
            obj.addParameter('epochObjLoomSpeed',loomSpeed);
            if obj.numObjects==2
                obj.addParameter('epochObj2Color',params.objColor2);
                obj.addParameter('epochObj2Position',[params.objXinit2,params.objYinit2]);
                obj.addParameter('epochObj2StartSize',startSize2);
                obj.addParameter('epochObj2LoomSpeed',loomSpeed2);
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