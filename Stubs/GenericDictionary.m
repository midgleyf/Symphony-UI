classdef GenericDictionary < handle
   
    properties
        Keys
        Values
    end
    
    methods
        function obj = GenericDictionary()
            obj = obj@handle();
            
            obj.Keys = {};
            obj.Values = {};
        end
        
        function Add(obj, key, value)
            for i = 1:numel(obj.Keys)
                if isequal(obj.Keys{i}, key)
                    obj.Values{i} = value;
                    return
                end
            end
            
            obj.Keys{end + 1} = key;
            obj.Values{end + 1} = value;
        end
        
        function c = ContainsKey(obj, key)
            for i = 1:numel(obj.Keys)
                if isequal(obj.Keys{i}, key)
                    c = true;
                    return
                end
            end
            
            c = false;
        end
        
        function v = Item(obj, key)
            for i = 1:numel(obj.Keys)
                if isequal(obj.Keys{i}, key)
                    v = obj.Values{i};
                    return
                end
            end
            
            error('Non-existent key');
        end
        
        function c = Count(obj)
            c = numel(obj.Keys);
        end
    end
    
end