%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IIOData < handle
   
    properties
        Data                     % GenericList
        SampleRate               % Measurement
        Configuration            % GenericDictionary
        Duration
    end
    
    methods
        function obj = IIOData(data, sampleRate, config)
            obj = obj@handle();
            
            if nargin < 3
                config = GenericDictionary();
            end
            
            obj.Data = data;
            obj.SampleRate = sampleRate;
            obj.Configuration = config;
            obj.Duration = obj.Data.Count / obj.SampleRate.Quantity;
        end
    end
    
end