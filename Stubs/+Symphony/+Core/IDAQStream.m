%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IDAQStream < Symphony.Core.ITimelineProducer
   
    properties
        Configuration
        Name
        SampleRate
        Active
        MeasurementConversionTarget
    end
    
    methods
        function obj = IDAQStream()
            obj = obj@Symphony.Core.ITimelineProducer();
            
            obj.Configuration = GenericDictionary();
            obj.Active = true;
        end
    end
end