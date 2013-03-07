%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef Measurement < handle
   
    properties
        Quantity
        Exponent
        BaseUnit
    end
    
    properties (Dependent)
        DisplayUnit
    end
    
    properties (Constant)
        baseUnits = {'Y', 'Z', 'E', 'P', 'T', 'G', 'M', 'k', 'h', 'da', 'd', 'c', 'm', 'µ', 'n', 'p', 'f', 'a', 'z', 'y', ''};
        baseExps = [24, 21, 18, 15, 12, 9, 6, 3, 2, 1, -1, -2, -3, -6, -9, -12, -15, -18, -21, -24, 0];
        UNITLESS = '';
    end
    
    
    methods
        
        function obj = Measurement(quantity, arg1, arg2)
            obj = obj@handle();
            
            obj.Quantity = quantity;

            if nargin == 2
                % e.g. Measurement(10, 'mV')
                [obj.BaseUnit, obj.Exponent] = splitUnit(arg1);
            elseif nargin == 3
                % e.g. Measurement(10, -3, 'V')
                if ~ismember(arg1, Symphony.Core.Measurement.baseExps)
                    error('Symphony:Core:Measurement', 'Unknown measurement exponent: %d', arg1);
                end
                obj.Exponent = arg1;
                obj.BaseUnit = arg2;
            end
        end
        
        
        function q = QuantityInBaseUnit(obj)
            q = obj.Quantity * 10 ^ obj.Exponent;
        end
        
        
        function du = get.DisplayUnit(obj)
            expInd = Symphony.Core.Measurement.baseExps == obj.Exponent;
            du = [Symphony.Core.Measurement.baseUnits{expInd} obj.BaseUnit];
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


function [u, e] = splitUnit(unitString)
    if length(unitString) < 2
        u = unitString;
        e = 0;
        return
    end
    
    for i = 1:length(Symphony.Core.Measurement.baseUnits)
        baseUnit = Symphony.Core.Measurement.baseUnits{i};
        if strncmp(unitString, baseUnit, length(baseUnit)) && length(unitString) > length(baseUnit)
            u = unitString(length(baseUnit) + 1:end);
            e = Symphony.Core.Measurement.baseExps(i);
            return
        end
    end
    
    error('Symphony:Core:Measurement', 'Unknown measurement units %s', unitString);
end
