classdef Circle < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Circle'
        plugInName = 'MovingObjects'
        xMonPix = 800;
        yMonPix = 600;
    end
    
    properties (Hidden)
        notCompletedSizes
    end

    properties
        preTime = 0.5;
        stimTime = 0.5;
        postTime = 0.5;
        interTrialInterval = [1 2];
        backgroundColor = 0;
        stimColor = 1;
        stimSize = [5,10,20,40];
        RFcenterX = 400;
        RFcenterY = 300;
        Xoffset = 0;
        Yoffset = 0;
    end
    
    
    methods
        
        function prepareRun(obj)
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            obj.notCompletedSizes = obj.stimSize;
        end
        
        function prepareEpoch(obj)
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.nLoops = 0;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Set object properties
            params.numObj = 1;
            params.objColor = obj.stimColor;
            params.objType = 'ellipse';
            params.objXinit = obj.RFcenterX+obj.Xoffset;
            params.objYinit = obj.RFcenterY+obj.Yoffset;
            
            % Pick a stim size from the stimSize vector; complete all sizes before repeating any
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedSizes),1);
            epochStimSize = obj.notCompletedSizes(randIndex);
            obj.notCompletedSizes(randIndex) = [];
            
            % Set nFrames and the number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = obj.preTime*frameRate;
            params.nFrames = round(obj.stimTime*frameRate);
            params.tFrames = params.nFrames;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime plus plenty of extra time to complete stop stimGL
            params.objLenX = [epochStimSize zeros(1,ceil((obj.postTime+obj.stimTime+10)/obj.stimTime))];
            params.objLenY = params.objLenX;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('epochSize', epochStimSize);
            
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
            if isempty(obj.notCompletedSizes)
                obj.notCompletedSizes = obj.stimSize;
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