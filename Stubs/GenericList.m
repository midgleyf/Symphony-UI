classdef GenericList < handle
   
    properties
        Items
    end
    
    methods
        function obj = GenericList()
            obj = obj@handle();
            
            obj.Items = {};
        end
        
        function Add(obj, item)
            obj.Items{end + 1} = item;
        end
        
        function i = Item(obj, index)
            i = obj.Items{index + 1};   % index is zero based
        end
        
        function c = Count(obj)
            c = numel(obj.Items);
        end
    end
    
end