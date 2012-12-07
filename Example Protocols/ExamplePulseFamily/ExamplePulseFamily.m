%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef ExamplePulseFamily < SymphonyProtocol

    properties (Constant)
        identifier = 'Symphony.ExamplePulseFamily'
        version = 1
        displayName = 'Example Pulse Family'
    end
    
    properties
        amp
        preTime = 50
        stimTime = 500
        tailTime = 50
        firstPulseSignal = 100
        incrementPerPulse = 10
        pulsesInFamily = uint16(11)
        preAndTailSignal = -60
        ampHoldSignal = -60
        numberOfAverages = uint16(5)
    end
    
    methods           
        
        function units = parameterUnits(obj, parameterName)
            % Call the base method to include any units it may already define.
            units = parameterUnits@SymphonyProtocol(obj, parameterName);
            
            % Return the appropriate units for each parameter in the protocol.
            switch parameterName
                case {'preTime', 'stimTime', 'tailTime'}
                    units = 'ms';
                case {'firstPulseSignal', 'incrementPerPulse', 'preAndTailSignal', 'ampHoldSignal'}
                    units = 'mV or pA';
            end
        end     
       
        
        function value = defaultParameterValue(obj, parameterName)
            % Call the base method to include any default values it may define.
            value = defaultParameterValue@SymphonyProtocol(obj, parameterName);
            
            % This method is useful if a default value can't be defined in the properties block (i.e. it is not a constant or simple expression).
            % For instance, if a default value depends on properties of the current rig configuration it must be defined here.
            switch parameterName
                case 'amp'
                    % Allow the amp to be selected from a list of all amps in the current rig configuration.
                    value = obj.rigConfig.multiClampDeviceNames();
            end
        end
        
        
        function prepareRun(obj)
            % Call the base method.
            prepareRun@SymphonyProtocol(obj);
            
            % Open figures showing the response and mean response of the amp.
            obj.openFigure('Mean Response', obj.amp);
            obj.openFigure('Response', obj.amp);
        end
        
        
        function [stim, units] = stimulusForPulseNum(obj, pulseNum)
            % Convert time to sample points.
            prePts = round(obj.preTime / 1e3 * obj.sampleRate);
            stimPts = round(obj.stimTime / 1e3 * obj.sampleRate);
            tailPts = round(obj.tailTime / 1e3 * obj.sampleRate);
            
            % Create pulse stimulus.
            stim = ones(1, prePts + stimPts + tailPts) * obj.preAndTailSignal;
            stim(prePts + 1:prePts + stimPts) = obj.incrementPerPulse * (pulseNum - 1) + obj.firstPulseSignal;
            
            % Convert the pulse stimulus to appropriate units for the current multiclamp mode.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                stim = stim * 1e-3; % mV to V
                units = 'V';
            else
                stim = stim * 1e-12; % pA to A
                units = 'A';
            end
        end
        
        
        function stimuli = sampleStimuli(obj)
            % Return a sample stimulus for display in the edit parameters window.
            stimuli = cell(obj.pulsesInFamily, 1);
            for i = 1:obj.pulsesInFamily         
                stimuli{i} = obj.stimulusForPulseNum(i);
            end
        end
       
        
        function prepareEpoch(obj)
            % Call the base method.
            prepareEpoch@SymphonyProtocol(obj);           
            
            % Set the amp hold signal.
            if strcmp(obj.rigConfig.multiClampMode(obj.amp), 'VClamp')
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal * 1e-3, 'V');
            else
                obj.setDeviceBackground(obj.amp, obj.ampHoldSignal * 1e-12, 'A');
            end
            
            % Add the amp pulse stimulus to the epoch.
            pulseNum = mod(obj.epochNum - 1, obj.pulsesInFamily) + 1;
            disp(pulseNum);
            [stim, units] = obj.stimulusForPulseNum(pulseNum);
            obj.addStimulus(obj.amp, [obj.amp '_Stimulus'], stim, units);
        end
        
        
        function keepGoing = continueRun(obj)
            % Check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            % Keep going until the requested number of epochs is reached.
            if keepGoing
                keepGoing = obj.epochNum < obj.numberOfAverages * obj.pulsesInFamily;
            end
        end
        
    end
    
end

