classdef StimGLProtocol < SymphonyProtocol
    
    properties (Constant, Abstract)
        plugInName
    end
    
    properties (Hidden)
        stimGL
    end
    
    properties
        % These properties are available to all StimGL plug-ins.
        numberOfFrames = uint32(0)   % the number of frames to run, 0 = no limit
        numberOfLoops = uint32(1)    % the number of times to repeat the plug-in
    end
    
    
    methods
        
        function params = pluginParameters(obj)
            params.nFrames = obj.numberOfFrames;
            params.nLoops = obj.numberOfLoops;
        end
        
        
        function prepareRun(obj)
            obj.openFigure('Response');
            
            % Connect to StimGL, starting the app if necessary.
            symphonyPath = mfilename('fullpath');
            parentDir = fileparts(symphonyPath);
            prevDir = cd(fullfile(parentDir, 'StimGL'));
            obj.stimGL = StimOpenGL;
            cd(prevDir);
            
            % Start the module in the paused state.
            SetParams(obj.stimGL, obj.plugInName, obj.pluginParameters());
            Start(obj.stimGL, obj.plugInName, 0);
        end
        
        
        function prepareEpoch(obj)
            % Create a dummy output signal so the epoch runs for the desired length.
            frameRate = double(GetRefreshRate(obj.stimGL));
            sampleRate = obj.deviceSampleRate('test-device', 'OUT');
            stimulus = zeros(1, double(obj.numberOfFrames) * double(obj.numberOfLoops) / frameRate * sampleRate.Quantity);
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            
            obj.setDeviceBackground('test-device', 0.0);
            
            obj.recordResponse('test-device');
            
            Unpause(obj.stimGL);
        end
        
        
        function completeEpoch(obj)
            % TODO: let StimGL pause/stop itself by checking for IsPaused() or Running()?
            Pause(obj.stimGL);
        end
        
        
        function keepGoing = continueRun(obj)
            if obj.numberOfFrames == 0 || obj.numberOfLoops == 0
                % The user must stop the protocol from running.
                keepGoing = true;
            else
                keepGoing = ~isempty(obj.stimGL.Running());
            end
        end
        
        
        function completeRun(obj)
            Stop(obj.stimGL);
            Close(obj.stimGL);
            obj.stimGL = [];
        end
        
    end
    
end