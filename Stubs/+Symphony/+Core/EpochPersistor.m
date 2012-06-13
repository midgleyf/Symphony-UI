%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef EpochPersistor < handle
   
    properties
    end
    
    methods (Abstract)
        BeginEpochGroup(obj, label, source, keywords, props, identifier, startTime);
        Serialize(obj, epoch);
        EndEpochGroup(obj);
        CloseDocument(obj);
    end
    
end