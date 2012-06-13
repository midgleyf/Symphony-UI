%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IDAQInputStream < Symphony.Core.IDAQStream
   
    properties
        Devices
    end
    
    methods
        function obj = IDAQInputStream()
            obj = obj@Symphony.Core.IDAQStream();
            
            obj.Devices = GenericList();
        end
    end
end