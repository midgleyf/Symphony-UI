function m = Measurement(quantity, unit)
    m.Quantity = quantity;
    m.Unit = unit;
    m.QuantityInBaseUnit = quantity;
end

% classdef Measurement < handle
%    
%     properties
%         Quantity
%         Unit
%     end
%     
%     methods
%         function obj = Measurement(quantity, unit)
%             obj = obj@handle();
%             
%             obj.Quantity = quantity;
%             obj.Unit = unit;
%         end
%         
%         function q = QuantityInBaseUnit(obj)
%             q = obj.Quantity;
%         end
%     end
%     
% end
