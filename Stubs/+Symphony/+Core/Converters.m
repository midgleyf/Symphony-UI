classdef Converters < handle
   
    properties (Constant)
        Conversions = struct('fromUnit', {}, 'toUnit', {}, 'func', {});
    end
    
    methods (Static)
        
        function Register(fromUnit, toUnit, func)
            % TODO: this doesn't actually work, the array remains empty.
            c = Symphony.Core.Converters.Conversions;
            c(end + 1) = struct('fromUnit', fromUnit, 'toUnit', toUnit, 'func', func);
            Symphony.Core.Converters.Conversions = c;
        end
        
    end
end
