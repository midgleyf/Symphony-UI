classdef StimGLProtocol < SymphonyProtocol
    
    properties (Constant, Abstract)
        plugInName
    end
    
    properties (Hidden)
        stimGL
        loopCount
        backgroundColor = [0.0 0.0 0.0]
    end
    
    properties
        % These properties are available to all StimGL plug-ins.
        animationDuration = 10.0        % the number of seconds to run the plug-in
        numberOfLoops = uint32(1)       % the number of times to run the plug-in
    end
    
    
    methods
        
        function obj = StimGLProtocol()
            obj = obj@SymphonyProtocol();
            
            % Connect to StimGL, starting the app if necessary.
            % Do this here so that the StimGL window can be positioned before any epochs are run.
            symphonyPath = mfilename('fullpath');
            parentDir = fileparts(symphonyPath);
            prevDir = cd(parentDir);
            obj.stimGL = StimOpenGL;
            cd(prevDir);
        end
        
        
        function params = pluginParameters(obj)
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.nFrames = obj.animationDuration * frameRate;
            
            % We _don't_ set nLoops because we handle that in Symphony via multiple epochs.
            params.nLoops = 1;
            
            % Set the background color used between epochs to be the same as what is used during epochs so that there is no flash.
            % The color used during an epoch can only be grayscale.
            params.interTrialBg = obj.backgroundColor;
            params.bgcolor = obj.backgroundColor(1);
        end
        
        
        function setBackgroundColor(obj, color)
            if ~isnumeric(color) || (numel(color) ~= 1 && numel(color) ~=3)
                error('The color parameter must be a single number or a triplet of numbers, e.g. 0.5 or [0.5 0.5 0.5].')
            end
            
            if numel(color) == 3
                if color(1) ~= color(2) || color(2) ~= color(3)
                    warning('Symphony:StimGLBackgroundColor', 'StimGL only supports grayscale background colors during epochs.')
                end
                
                color = mean(color);
            end
            
            obj.backgroundColor = [color color color];
        end
        
        
        function prepareRun(obj)
            obj.openFigure('Response');
            
            obj.loopCount = 1;
        end
        
        
        function prepareEpoch(obj)
            % Create a dummy output signal so the epoch runs for the desired length.
            sampleRate = obj.deviceSampleRate('test-device', 'OUT');
            stimulus = zeros(1, floor(double(obj.animationDuration) * sampleRate.Quantity));
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            
            obj.setDeviceBackground('test-device', 0.0);
            
            obj.recordResponse('test-device');
            
            SetParams(obj.stimGL, obj.plugInName, obj.pluginParameters());
            Start(obj.stimGL, obj.plugInName, 1);
        end
        
        
        function completeEpoch(obj)
            % TODO: let StimGL pause/stop itself by checking for IsPaused() or Running()?
            Stop(obj.stimGL);
            obj.loopCount = obj.loopCount + 1;
        end
        
        
        function keepGoing = continueRun(obj)
            if obj.numberOfLoops == 0
                % The user must stop the protocol from running.
                keepGoing = true;
            else
                keepGoing = obj.loopCount <= obj.numberOfLoops;
            end
        end
        
        
        function completeRun(obj)
            Stop(obj.stimGL);
        end
        
        
        function delete(obj)
            Close(obj.stimGL);
            obj.stimGL = [];
        end
        
    end
    
end