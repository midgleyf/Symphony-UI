classdef MovingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Moving Objects'
        plugInName = 'MovingObjects'
        xMonPix = 1280;
        yMonPix = 720;
    end
    
    properties (Hidden)
        trialTypes
        notCompletedTrialTypes
    end

    properties
        preTime = 1;
        postTime = 2;
        interTrialInterval = [1 4];
        backgroundColor = 0;
        objectShape = {'ellipse','box'};
        objectColor = 1;
        objectSize = 25;
        RFcenterX = 400;
        RFcenterY = 300;
        Xoffset = 0;
        Yoffset = 0;
        objectSpeed = 10;
        objectDir = 0:45:315;
    end
    
    
    methods
        
        function set.objectShape(obj,objectShape)
            obj.objectShape = char(objectShape);
        end
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get all combinations of trial types based on object direction, speed, and size
            obj.trialTypes = allcombs(obj.objectDir,obj.objectSpeed,obj.objectSize);
            obj.notCompletedTrialTypes = 1:size(obj.trialTypes,1);
        end
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Set constant parameters
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.wrapEdge = 1;
            params.nLoops = 0;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Set object properties
            params.numObj = 1;
            params.objColor = obj.objectColor;
            params.objType = obj.objectShape;
            % pick a combination of object direction/speed/size from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            randIndex = randi(numel(obj.notCompletedTrialTypes),1);
            epochTrialType = obj.notCompletedTrialTypes(randIndex);
            obj.notCompletedTrialTypes(randIndex) = [];
            angle = obj.trialTypes(epochTrialType,1);
            speed = obj.trialTypes(epochTrialType,2);
            objSize = obj.trialTypes(epochTrialType,3);
            % deterine object path, velocity components, and number of frames to complete path
            Xpos=obj.RFcenterX+obj.Xoffset;
            Ypos=obj.RFcenterY+obj.Yoffset;
            if angle==0
                params.objXinit = Xpos;
                params.objYinit = 0;
                params.objVelX = 0;
                params.objVelY = speed;
                params.nFrames = round(obj.yMonPix/speed);
            elseif angle>0 && angle<90
                m = tand(90-angle);
                xintercept = Xpos-Ypos/m;
                yintercept = -m*xintercept;
                if xintercept<0
                    params.objXinit = 0;
                    params.objYinit = yintercept;
                else
                    params.objXinit = xintercept;
                    params.objYinit = 0;
                end
                params.objVelX = round(speed*cosd(90-angle));
                params.objVelY = round(speed*sind(90-angle));
                Xend = (obj.yMonPix-yintercept)/m;
                if Xend>obj.xMonPix
                    Xend=obj.xMonPix;
                end
                Yend = m*obj.xMonPix+yintercept;
                if Yend>obj.yMonPix
                    Yend=obj.yMonPix;
                end
                distance = sqrt((Xend-params.objXinit)^2+(Yend-params.objYinit)^2);
                params.nFrames = round(distance/speed);
            elseif angle==90
                params.objXinit = 0;
                params.objYinit = Ypos;
                params.objVelX = speed;
                params.objVelY = 0;
                params.nFrames = round(obj.xMonPix/speed);
            elseif angle>90 && angle<180
                m = -tand(angle-90);
                xintercept = Xpos-(obj.yMonPix-Ypos)/-m;
                yintercept = -m*xintercept;
                if xintercept<0
                    params.objXinit = 0;
                    params.objYinit = obj.yMonPix+yintercept;
                else
                    params.objXinit = xintercept;
                    params.objYinit = obj.yMonPix;
                end
                params.objVelX = round(speed*cosd(angle-90));
                params.objVelY = -round(speed*sind(angle-90));
                Xend = (-obj.yMonPix-yintercept)/m;
                if Xend>obj.xMonPix
                    Xend=obj.xMonPix;
                end
                Yend = m*obj.xMonPix+yintercept;
                if Yend<-obj.yMonPix
                    Yend = 0;
                else
                    Yend = obj.yMonPix+Yend;
                end
                distance = sqrt((Xend-params.objXinit)^2+(Yend-params.objYinit)^2);
                params.nFrames = round(distance/speed);
            elseif angle==180
                params.objXinit = Xpos;
                params.objYinit = obj.yMonPix;
                params.objVelX = 0;
                params.objVelY = -speed;
                params.nFrames = round(obj.yMonPix/speed);
            elseif angle>180 && angle<270
                m = tand(270-angle);
                xintercept = -obj.xMonPix+Xpos+(obj.yMonPix-Ypos)/m;
                yintercept = -m*xintercept;
                if xintercept>0
                    params.objXinit = obj.xMonPix;
                    params.objYinit = obj.yMonPix+yintercept;
                else
                    params.objXinit = obj.xMonPix+xintercept;
                    params.objYinit = obj.yMonPix;
                end
                params.objVelX = -round(speed*cosd(270-angle));
                params.objVelY = -round(speed*sind(270-angle));
                Xend = (-obj.yMonPix-yintercept)/m;
                if Xend<-obj.xMonPix
                    Xend = 0;
                else
                    Xend = obj.xMonPix+Xend;
                end
                Yend = m*-obj.xMonPix+yintercept;
                if Yend<-obj.yMonPix
                    Yend = 0;
                else
                    Yend = obj.yMonPix+Yend;
                end
                distance = sqrt((Xend-params.objXinit)^2+(Yend-params.objYinit)^2);
                params.nFrames = round(distance/speed);
            elseif angle==270
                params.objXinit = obj.xMonPix;
                params.objYinit = Ypos;
                params.objVelX = -speed;
                params.objVelY = 0;
                params.nFrames = round(obj.xMonPix/speed);
            elseif angle>270 && angle<360
                m = -tand(angle-270);
                xintercept = -obj.xMonPix+Xpos+Ypos/-m;
                yintercept = -m*xintercept;
                if xintercept>0
                    params.objXinit = obj.xMonPix;
                    params.objYinit = yintercept;
                else
                    params.objXinit = obj.xMonPix+xintercept;
                    params.objYinit = 0;
                end
                params.objVelX = -round(speed*cosd(angle-270));
                params.objVelY = round(speed*sind(angle-270));
                Xend = (obj.yMonPix-yintercept)/m;
                if Xend<-obj.xMonPix
                    Xend = 0;
                else
                    Xend = obj.xMonPix+Xend;
                end
                Yend = m*-obj.xMonPix+yintercept;
                if Yend>obj.yMonPix
                    Yend = obj.yMonPix;
                end
                distance = sqrt((Xend-params.objXinit)^2+(Yend-params.objYinit)^2);
                params.nFrames = round(distance/speed);
            end
            
            % Set number of delay frames for preTime
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.delay = obj.preTime*frameRate;
            
            % Pad object length vector with zeros to make object disappear
            % during postTime plus plenty of extra time to complete stop stimGL
            params.tFrames = params.nFrames;
            stimTime = params.nFrames/frameRate;
            params.objLenX = [objSize zeros(1,ceil((obj.postTime+stimTime+10)/stimTime))];
            params.objLenY = params.objLenX;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('objectEpochDir', angle);
            obj.addParameter('objectEpochSpeed', speed);
            obj.addParameter('objectEpochSize', objSize);
            obj.addParameter('stimFrames', params.nFrames);
            obj.addParameter('stimTime', stimTime);
            
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
            
            % if all trial types completed, reset completedTrialTypes and start a new loop
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