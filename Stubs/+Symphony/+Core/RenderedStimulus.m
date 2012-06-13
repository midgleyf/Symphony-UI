%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef RenderedStimulus < handle
   
    properties
        StimulusID
        Units
        Parameters
        Data
    end
    
    methods
        function obj = RenderedStimulus(identifier, units, parameters, data)
            obj = obj@handle();
            
            obj.StimulusID = identifier;
            obj.Units = units;
            obj.Parameters = parameters;
            obj.Data = data;
        end
        
        function d = Duration(obj)
            d = obj.Data.Duration;
        end
    end
    
end