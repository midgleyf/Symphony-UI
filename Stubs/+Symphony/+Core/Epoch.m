%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Epoch < handle
   
    properties
        ProtocolID
        ProtocolParameters
        Stimuli
        Responses
        Identifier
        StartTime
        Background
        Keywords
    end
    
    methods
        function obj = Epoch(identifier, parameters)
            obj = obj@handle();
            
            obj.ProtocolID = identifier;
            if nargin == 2
                obj.ProtocolParameters = parameters;
            else
                obj.ProtocolParameters = GenericDictionary();
            end
            obj.Stimuli = GenericDictionary();
            obj.Responses = GenericDictionary();
            obj.Identifier = char(java.util.UUID.randomUUID());
            obj.Background = GenericDictionary();
            obj.Keywords = GenericList();
        end
        
        function SetBackground(obj, device, background, sampleRate)
            obj.Background.Add(device, Symphony.Core.Epoch.EpochBackground(background, sampleRate));
        end
    end
    
    methods (Static)
        function eb = EpochBackground(background, sampleRate)
            eb.Background = background;
            eb.SampleRate = sampleRate;
        end
    end
end