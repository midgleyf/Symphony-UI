classdef GenericList < handle
   
    properties
        Items
        itemCount
    end
    
    methods
        function obj = GenericList(~, objCount)
            obj = obj@handle();
            
            if nargin < 2
                objCount = 0;
            end
            
            obj.Items = cell(1, objCount);
            obj.itemCount = 0;
        end
        
        function Add(obj, item)
            obj.itemCount = obj.itemCount + 1;
            obj.Items{obj.itemCount} = item;
        end
        
        function i = Item(obj, index)
            i = obj.Items{index + 1};   % index is zero based
        end
        
        function c = Count(obj)
            c = obj.itemCount;
        end
    end
    
end