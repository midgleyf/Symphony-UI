%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef TestProtocol < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.test'
        version = 1
        displayName = 'Test'
    end
    
    properties
        epochMax = uint8(4) 
        stimSamples = uint32(100) 
        rampFrequency = true
    end
    
    methods
        
        function dn = requiredDeviceNames(obj) %#ok<MANU>
            dn = {'Amplifier_Ch1'};
        end
        
        
        function [stimulus, freqScale] = stimulusForEpoch(obj, epochNum)
            if obj.rampFrequency                            % if checkbox engaged
                freqScale = 1000.0 / double(epochNum);          % decrease the factor by which the period of the sine wave is slowed as the epoch number increases
            else                                            % if checkbox is not engaged    
                freqScale = 1000.0;                             % the period of the sine wave is ~6300 (2 Pi * 1000) points (or 0.63s assuming 10 KHz sampling; see below) 
            end
            stimulus = sin((1:double(obj.stimSamples)) / freqScale) .* 5e-3;   % given the frequency scale (aka period), and the number of samples in the stimulus (defined from the properties menu), compute the stimulus for this epoch
        end
        
        
        function stimuli = sampleStimuli(obj)     
            stimuli = cell(obj.epochMax, 1);                    % create a cell for each of the epochs
            for i = 1:obj.epochMax                                % for each of the epochs
                stimuli{i} = obj.stimulusForEpoch(i);               % put the stimulus for that epoch in the appropriate cell
            end
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            obj.openFigure('Response');
            obj.openFigure('Custom', 'Name', 'Foo', ...
                                     'UpdateCallback', @updateFigure);
        end
        
        
        function updateFigure(obj, axesHandle)
            % Trivial example that just draws the current epoch number in the figure.
            cla(axesHandle)
            set(axesHandle, 'XTick', [], 'YTick', []);
            text(0.5, 0.5, ['Epoch ' num2str(obj.epochNum)], 'FontSize', 48, 'HorizontalAlignment', 'center');
        end
        
        
        function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus, freqScale] = obj.stimulusForEpoch(obj.epochNum);     % for this epoch
            obj.addParameter('freqScale', freqScale);                        % grab and save the freqScale parameter defined above   
            obj.addStimulus('Amplifier_Ch1', 'amp_ch1_stimulus', stimulus, 'V');  % grab the stimulus (also defined above), give it a name, and add it to the defined device; only works properly in voltage clamp
            
            %obj.addStimulus('LED',     'LED stimulus',     [0 0 0 0 1 1 1 1]);
            %obj.addStimulus('Shutter', 'Shutter stimulus', [0 0 1 1 0 0 1 1]);
            %obj.addStimulus('Lock',    'Lock stimulus',    [0 1 0 1 0 1 0 1]);
        end
        
        
        function keepGoing = continueRun(obj)
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.epochNum < obj.epochMax;                        % keep going as long as the epochNum is less than the epochMax
            end
        end

    end
end