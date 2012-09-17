% Creates a single stimulus composed of mean + flash.
% Implements SymphonyProtocol
%
%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html
%
%  Modified by TA 9.8.12 from LED Family to create a single LED pulse protocol

classdef LEDFlash < SymphonyProtocol

    properties (Constant)
        identifier = 'helsinki.yliopisto.pal'
        version = 1
        displayName = 'LED Flash'
    end
    
    properties
        stimPoints = uint16(100);
        prePoints = uint16(1000);
        tailPoints = uint16(4000);
        stimAmplitude = 0.5;
        lightMean = 0.0;
        preSynapticHold = -60;
        numberOfAverages = uint8(5);
        interpulseInterval = 0.6;
        continuousRun = false;
    end
    
    properties (Dependent = true, SetAccess = private) % these properties are inherited - i.e., not modifiable
        % ampOfLastStep;
    end
    
    methods
        
        function [stimulus, lightAmplitude] = stimulusForEpoch(obj, ~) % epoch Num is usually required
            % Calculate the light amplitude for this epoch.
            % phase = single(mod(epochNum - 1, obj.stepsInFamily));               % Frank's clever way to determine which flash in a family to deliver
            lightAmplitude = obj.stimAmplitude; % * obj.ampStepScale ^ phase;   % Frank's clever way to determine the amplitude of the flash family to deliver
            
            % Create the stimulus
            stimulus = ones(1, obj.prePoints + obj.stimPoints + obj.tailPoints) * obj.lightMean;
            stimulus(obj.prePoints + 1:obj.prePoints + obj.stimPoints) = lightAmplitude;
        end
        
        
        function stimulus = sampleStimuli(obj) % Return a cell array
            % you can only create one stimulus with this protocol TA
            stimulus{1} = obj.stimulusForEpoch();
        end
        
        
        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
            %obj.setDeviceBackground('LED', obj.lightMean, 'V');
            
%             if strcmp(obj.rigConfig.multiClampMode('Amplifier_Ch1'), 'IClamp')
%                 obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-12, 'A');
%             else
%                 obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-3, 'V');
%             end
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);

            obj.openFigure('Response');
            obj.openFigure('Mean Response', 'GroupByParams', {'lightAmplitude'});
            obj.openFigure('Response Statistics', 'StatsCallback', @responseStatistics);
        end
        
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus, lightAmplitude] = obj.stimulusForEpoch(obj.epochNum);
            obj.addParameter('lightAmplitude', lightAmplitude);
            %obj.addStimulus('LED', 'test-stimulus', stimulus, 'V');    %
            obj.setDeviceBackground('LED', obj.lightMean, 'V');
            if strcmp(obj.multiClampMode, 'VClamp')
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-3, 'V');
            else
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-12, 'A');
            end 
            obj.addStimulus('LED', 'LED stimulus', stimulus, 'V');    %
        end
        
        
        function stats = responseStatistics(obj)
            r = obj.response();
            
            % baseline mean and var
            if ~isempty(r)
                stats.mean = mean(r(1:obj.prePoints));
                stats.var = var(r(1:obj.prePoints));
            else
                stats.mean = 0;
                stats.var = 0;
            end
        end
        
        
        function completeEpoch(obj)
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % Pause for the inter-pulse interval.
            pause on
            pause(obj.interpulseInterval);
        end
        
        
        function keepGoing = continueRun(obj)   
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.epochNum < obj.numberOfAverages;
            end
        end
        
        
%         function amp = get.ampOfLastStep(obj)   % The product of the number of steps in family, the first step amplitude, and the 'scale factor'
%             amp = obj.baseLightAmplitude * obj.ampStepScale ^ (obj.stepsInFamily - 1);
%         end

    end
end