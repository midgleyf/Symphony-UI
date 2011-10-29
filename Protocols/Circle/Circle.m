classdef Circle < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Circle'
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
        objectColor = [0.5,1];
        objectSize = [1,5,10,20];
        RFcenterX = 0;
        RFcenterY = 0;
        Xoffset = 0;
        Yoffset = 0;
    end
    
    methods
        
        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
            % TODO: remove this once the base class is handling the sample rate
            obj.rigConfig.sampleRate = obj.samplingRate;
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get all combinations of trial types based on object color and size
            obj.trialTypes = allcombs(obj.objectColor,obj.objectSize);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Pick a combination of object color and size from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            epochObjectColor = obj.trialTypes(epochTrialType,1);
            epochObjectSize = obj.trialTypes(epochTrialType,2);
            
            % Set object properties
            params.numObj = 1;
            params.objColor = epochObjectColor;
            params.objType = 'ellipse';
            % get object position and size in pixels
            objectPosDeg = [obj.RFcenterX+obj.Xoffset,obj.RFcenterY+obj.Yoffset];
            screenDistPix = obj.screenDist*(obj.xMonPix/obj.screenWidth);
            screenHeightBelowPix = obj.screenHeightBelow*(obj.xMonPix/obj.screenWidth);
            objectEdgesXPix = obj.xMonPix/2+screenDistPix*tand([objectPosDeg(1)-epochObjectSize/2,objectPosDeg(1)+epochObjectSize/2]);
            objectEdgesYPix = screenHeightBelowPix+screenDistPix*tand([objectPosDeg(2)-epochObjectSize/2,objectPosDeg(2)+epochObjectSize/2]);
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
            obj.addParameter('epochObjectColor', epochObjectColor);
            obj.addParameter('epochObjectSize', epochObjectSize);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            stimulus = zeros(1,floor(obj.samplingRate*(obj.preTime+obj.stimTime+obj.postTime)));
            obj.addStimulus('Amplifier_Ch1','Amplifier_Ch1 stimulus',stimulus,'A');
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 1);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            
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