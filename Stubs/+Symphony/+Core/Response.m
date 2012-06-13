%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Response < handle
   
    properties
        Data
        DataConfigurationSpans
        SampleRate
        InputTime
        Duration
    end
    
    methods
        function obj = Response()
            obj = obj@handle();
            
            obj.Data = GenericList();
            obj.DataConfigurationSpans = GenericList();
            obj.SampleRate = Symphony.Core.Measurement(10000, 'Hz');
            obj.InputTime = now;
            obj.Duration = 0;   % TODO: calculate from length of data and sample rate?
        end
    end
    
end