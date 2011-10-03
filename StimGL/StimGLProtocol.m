classdef StimGLProtocol < SymphonyProtocol
    
    properties (Constant, Abstract)
        plugInName
    end
    
    properties (Hidden)
        stimGL
        loopCount
    end
    
    properties
        % These properties are available to all StimGL plug-ins.
        animationDuration = 1;       % the number of seconds to run the plug-in
        numberOfLoops = uint32(1);       % the number of times to run the plug-in
    end
    
    
    methods
        
        function obj = StimGLProtocol()
            obj = obj@SymphonyProtocol();
            
            % Connect to StimGL, starting the app if necessary.
            % Do this here so that the StimGL window can be positioned before any epochs are run.
            symphonyPath = mfilename('fullpath');
            parentDir = fileparts(symphonyPath);
            prevDir = cd(parentDir);
            try
                obj.stimGL = StimOpenGL;
                cd(prevDir);
            catch ME
                cd(prevDir);
                throw(ME);
            end
        end
        
        
        function params = pluginParameters(obj)
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.nFrames = obj.animationDuration * frameRate;
            
            % We _don't_ set nLoops because we handle that in Symphony via multiple epochs.
            params.nLoops = 1;
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
            
            % Start the StimGL plug-in.
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