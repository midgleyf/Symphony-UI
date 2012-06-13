%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef MultiClampCommander < handle
   
    properties
        SerialNumber
        Channel
        Clock
    end
    
    methods
        function obj = MultiClampCommander(serialNumber, channel, clock)
            obj.SerialNumber = serialNumber;
            obj.Channel = channel;
            obj.Clock = clock;
        end
    end
end