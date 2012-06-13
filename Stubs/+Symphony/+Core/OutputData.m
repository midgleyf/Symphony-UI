%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef OutputData < Symphony.Core.IOData
   
    properties
        IsLast
    end
    
    methods
        function obj = OutputData(data, sampleRate, isLast)
            obj = obj@Symphony.Core.IOData(data, sampleRate);
            
            obj.IsLast = isLast;
        end
    end
    
end