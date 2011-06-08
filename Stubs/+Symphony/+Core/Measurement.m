classdef Measurement < handle
   
    properties
        Quantity
        Unit
    end
    
    methods
        function obj = Measurement(quantity, unit)
            obj = obj@handle();
            
            obj.Quantity = quantity;
            obj.Unit = unit;
        end
        
        function q = QuantityInBaseUnit(obj)
            q = obj.Quantity;
        end
    end
    
    methods (Static)
        function m = FromArray(array, unit)
            m = NET.createGeneric('System.Collections.Generic.List', {'Symphony.Core.Measurement'}, length(array));
            for i=1:length(array)
                m.Add(Symphony.Core.Measurement(array(i), unit));
            end
        end
    end
    
end
