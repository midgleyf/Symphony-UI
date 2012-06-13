%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Measurement < handle
   
    properties
        Quantity
        Exponent
        Unit
    end
    
    methods
        function obj = Measurement(quantity, exponent, unit)
            obj = obj@handle();
            
            if nargin == 2
                unit = exponent;
                exponent = 0;
            end
            
            obj.Quantity = quantity;
            obj.Exponent = exponent;
            obj.Unit = unit;
        end
        
        function q = QuantityInBaseUnit(obj)
            q = obj.Quantity * 10 ^ obj.Exponent;
        end
    end
    
    methods (Static)
        function m = FromArray(array, unit)
            m = NET.createGeneric('System.Collections.Generic.List', {'Symphony.Core.Measurement'}, length(array));
            for i=1:length(array)
                m.Add(Symphony.Core.Measurement(array(i), unit));
            end
        end
        
        function a = ToQuantityArray(list)
            a = cellfun(@(x) x.Quantity, list.Items);
        end
        
        function u = HomogenousUnits(list)
            u = list.Item(0).Unit;
        end
    end
    
end
