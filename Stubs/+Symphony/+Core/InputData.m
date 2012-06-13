%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef InputData < Symphony.Core.IOData
   
    properties
        InputTime
    end
    
    methods
        function obj = InputData(data, sampleRate, inputTime, config)
            if nargin < 4
                config = GenericDictionary();
            end
            
            obj = obj@Symphony.Core.IOData(data, sampleRate, config);
            
            obj.InputTime = inputTime;
        end
    end
    
end