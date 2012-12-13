% Describes protocol class parameters (properties in a protocol class).
%
% ProtocolParameter objects are obtained from the parameterProperty method of a protocol.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef ParameterProperty < handle
    
    properties (SetAccess = private)
        meta
    end
    
    properties
        defaultValue
        units
    end
    
    methods
        
        function obj = ParameterProperty(metaProperty)
            if ~isa(metaProperty, 'meta.property')
                error('metaProperty must be of class meta.property');
            end
            
            obj = obj@handle();
            obj.meta = metaProperty;
        end
        
        
        function set.defaultValue(obj, value)
            if obj.meta.Dependent
                error('Cannot define the default value of a dependent parameter');
            end
            obj.defaultValue = value;
        end
        
        
        function value = get.defaultValue(obj)          
            value = [];
            if ~isempty(obj.defaultValue)
                value = obj.defaultValue;
            elseif obj.meta.HasDefault
                value = obj.meta.DefaultValue;
            end
        end
        
    end
    
end

