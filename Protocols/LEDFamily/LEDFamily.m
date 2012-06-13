%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef LEDFamily < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.LEDFamily'
        version = 1
        displayName = 'LED Family'
    end
    
    properties
        stimPoints = uint16(100);
        prePoints = uint16(1000);
        tailPoints = uint16(4000);
        baseLightAmplitude = 0.5;
        stepsInFamily = uint8(3);
        ampStepScale = 2.0;
        lightMean = 0.0;
        preSynapticHold = -60;
        numberOfAverages = uint8(5);
        interpulseInterval = 0.6;
        continuousRun = false;
    end
    
    properties (Dependent = true, SetAccess = private) % these properties are inherited - i.e., not modifiable
        ampOfLastStep;
    end
    
    methods
        
        function [stimulus, lightAmplitude] = stimulusForEpoch(obj, epochNum)
            % Calculate the light amplitude for this epoch.
            phase = single(mod(epochNum - 1, obj.stepsInFamily));               % Frank's clever way to determine which flash in a family to deliver
            lightAmplitude = obj.baseLightAmplitude * obj.ampStepScale ^ phase;   % Frank's clever way to determine the amplitude of the flash family to deliver
            
            % Create the stimulus
            stimulus = ones(1, obj.prePoints + obj.stimPoints + obj.tailPoints) * obj.lightMean;
            stimulus(obj.prePoints + 1:obj.prePoints + obj.stimPoints) = lightAmplitude;
        end
        
        
        function stimuli = sampleStimuli(obj)
            stimuli = cell(obj.stepsInFamily, 1);
            for i = 1:obj.stepsInFamily
                stimuli{i} = obj.stimulusForEpoch(i);
            end
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
            
            stats.mean = mean(r);
            stats.var = var(r);
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
                keepGoing = obj.epochNum < obj.stepsInFamily * obj.numberOfAverages;
            end
        end
        
        
        function amp = get.ampOfLastStep(obj)   % The product of the number of steps in family, the first step amplitude, and the 'scale factor'
            amp = obj.baseLightAmplitude * obj.ampStepScale ^ (obj.stepsInFamily - 1);
        end

    end
end