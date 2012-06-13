%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef DAQOutputStream < Symphony.Core.IDAQOutputStream
    methods
        function obj = DAQOutputStream(name)
            obj = obj@Symphony.Core.IDAQOutputStream();
            
            obj.Name = name;
        end
    end
end