%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Guid < handle
   
    properties
        id
    end
    
    methods (Static)
        function guid = NewGuid()
            id = java.util.UUID.randomUUID();
            guid = System.Guid(id);
        end
    end
    
    methods
        function obj = Guid(id)
            obj.id = id;
        end
        
        function s = ToString(obj)
            s = char(obj.id);
        end
    end
end