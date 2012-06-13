%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Converters < handle
    
    methods (Static)
        
        function Register(fromUnit, toUnit, func)
            global unitConversions;
            
            if isempty(unitConversions)
                unitConversions = struct('fromUnit', fromUnit, 'toUnit', toUnit, 'func', func);
            else
                unitConversions(end + 1) = struct('fromUnit', fromUnit, 'toUnit', toUnit, 'func', func);
            end
        end
        
        function t = Test(fromUnit, toUnit)
            global unitConversions;
            
            t = false;
            for i = 1:length(unitConversions)
                if strcmp(unitConversions(i).fromUnit, fromUnit) && strcmp(unitConversions(i).toUnit, toUnit)
                    t = true;
                    break
                end
            end
        end
        
        function Clear()
            global unitConversions;
            
            unitConversions = [];
        end
            
    end
end
