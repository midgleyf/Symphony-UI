%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

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
        numberOfLoops = uint32(1);       % the number of times (epochs) to run the plug-in
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
        
        
        function s = epochDuration(obj) %#ok<MANU>
            % Return the number of seconds the current epoch will take.
            s = 1;
        end
        
        
        function params = pluginParameters(obj)
            frameRate = double(GetRefreshRate(obj.stimGL));
            params.nFrames = obj.epochDuration() * frameRate;
            
            % We _don't_ set nLoops because we handle that in Symphony via multiple epochs.
            params.nLoops = 0;
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.loopCount = 1;
        end
        
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            % Create a dummy output signal so the epoch runs for the desired length.
            % If a sub-class adds its own stimulus then this one will be replaced.
            % TODO: make sure to pick a device with an output stream
            stimulus = zeros(1, floor(obj.epochDuration() * obj.sampleRate));
            device = obj.rigConfig.devices();
            obj.addStimulus(device{1}.Name, 'StimGL_dummy_stimulus', stimulus);
            
            % Start the StimGL plug-in.
            SetParams(obj.stimGL, obj.plugInName, obj.pluginParameters());
            Start(obj.stimGL, obj.plugInName, 0);
            Unpause(obj.stimGL);
        end
        
        
        function completeEpoch(obj)
            % Tell StimGL to stop the animation.
            Stop(obj.stimGL);
            
            obj.loopCount = obj.loopCount + 1;
            
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
        end
        
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing && obj.numberOfLoops > 0
                keepGoing = obj.loopCount <= obj.numberOfLoops;
            end
        end
        
        
        function completeRun(obj)
            Stop(obj.stimGL);
            
            % Call the base class method.
            completeRun@SymphonyProtocol(obj);
        end
        
        
        function delete(obj)
            % We may throw during instantiation, in which case we may not have a stimGL to close
            if (~isempty(obj.stimGL))
                Close(obj.stimGL);
                obj.stimGL = [];
            end
        end
        
    end
    
end