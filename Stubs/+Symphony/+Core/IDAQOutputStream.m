%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IDAQOutputStream < Symphony.Core.IDAQStream
   
    properties
        Device
        HasMoreData
        Background
    end
    
    methods
        function obj = IDAQOutputStream()
            obj = obj@Symphony.Core.IDAQStream();
        end
    end
end