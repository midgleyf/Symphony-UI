classdef MovingObjects < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Moving Objects'
        plugInName = 'MovingObjects'
        xMonPix = 800;
        yMonPix = 600;
    end
    
    properties (Hidden)
        trialTypes
        completedTrialTypes
    end

    properties
        preTime = 1;
        postTime = 2;
        interTrialRange = [1 4];
        backgroundColor = 0;
        objectShape = {'ellipse', 'box', 'sphere'}; % same for all objects
        numObjects = {'1','2'};
        objectColor = 1;
        %object2Color = 1;
        objectSize = 25;
        %object2Size = 10;
        RFcenterX = 400;
        RFcenterY = 300;
        objectXoffset = 0;
        objectYoffset = 0;
        %object2Xoffset = 100;
        %object2Yoffset = 100;
        objectSpeed = 10;
        %object2Speed = 10;
        objectDir = 0:45:315;
        %object2Dir = 0;
    end
    
    
    methods
        
        function prepareRun(obj)
            obj.loopCount = 1;
            
            % Prepare figures
            %obj.openFigure('Response');
            
            % Get all combinations of trial types based on object
            % direction, speed, and size
            obj.trialTypes=zeros(numel(obj.objectDir)*numel(obj.objectSpeed)*numel(obj.objectSize),3);
            row=1;
            for i=1:numel(obj.objectDir)
                for j=1:numel(obj.objectSpeed)
                    for k=1:numel(obj.objectSize)
                        obj.trialTypes(row,1)=obj.objectDir(i);
                        obj.trialTypes(row,2)=obj.objectSpeed(j);
                        obj.trialTypes(row,3)=obj.objectSize(k);
                        row=row+1;
                    end
                end
            end
            obj.completedTrialTypes=false(size(obj.trialTypes,1),1);
        end
        
        function prepareEpoch(obj)
            params.x_mon_pix = obj.xMonPix;
            params.y_mon_pix = obj.yMonPix;
            params.wrapEdge = 1;
            params.nLoops = 0;
            params.bgcolor = obj.backgroundColor;
            params.interTrialBg = repmat(obj.backgroundColor,1,3);
            
            % Set object properties
            params.numObj = obj.numObjects;
            params.objColor = obj.objectColor;
            params.objType = obj.objectShape;
            % pick a combination of object direction/speed/size from the trialTypes list
            % complete all combinations before repeating any particular combination
            rng('shuffle');
            completedTrialType = true;
            while completedTrialType
                trialType = randi(size(obj.trialTypes,1),1);
                if ~obj.completedTrialTypes(trialType)
                    obj.completedTrialTypes(trialType) = true;
                    completedTrialType = false;
                end
            end
            angle = obj.trialTypes(trialType,1);
            speed = obj.trialTypes(trialType,2);
            objSize = obj.trialTypes(trialType,3);
            % deterine object path, velocity components, and number of frames to complete path
            Xpos=obj.RFcenterX+obj.objectXoffset;
            Ypos=obj.RFcenterY+obj.objectYoffset;
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
            params.objLenX = [objSize zeros(1,ceil(obj.postTime+stimTime+10/stimTime))];
            params.objLenY = params.objLenX;
            
            % Add epoch-specific parameters for ovation
            obj.addParameter('objectEpochDir', angle);
            obj.addParameter('objectEpochSpeed', speed);
            obj.addParameter('objectEpochSize', objSize);
            obj.addParameter('stimFrames', params.nFrames);
            obj.addParameter('stimTime', stimTime);
            
            % Create a dummy stimulus so the epoch runs for the desired length
            sampleRate = obj.deviceSampleRate('test-device', 'OUT');
            stimulus = zeros(1, floor(sampleRate.Quantity*(obj.preTime+stimTime+obj.postTime)));
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            
            % Start the StimGL plug-in
            SetParams(obj.stimGL, obj.plugInName, params);
            Start(obj.stimGL, obj.plugInName, 1);
        end
        
        function completeEpoch(obj)
            Stop(obj.stimGL);
            % if all trial types completed, reset completedTrialTypes and start a new loop
            if all(obj.completedTrialTypes)
                obj.completedTrialTypes = false(size(obj.trialTypes,1),1);
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
                pause(rand(1)*diff(obj.interTrialRange)+obj.interTrialRange(1));
            end
        end
       
        function completeRun(obj)
            Stop(obj.stimGL);
        end
        
    end
    
end