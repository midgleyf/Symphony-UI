%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef IHardwareController < handle
    
    properties
        Running
        Configuration
    end
    
    methods
        
        function obj = IHardwareController()
            obj.Running = false;
            obj.Configuration = GenericDictionary();
        end
        
        function Start(obj, ~)
            obj.Running = true;
        end
        
        function Stop(~)
            obj.Running = false;
        end
        
        function BeginSetup(~)
        end
        
    end
    
end