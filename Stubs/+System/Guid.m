classdef Guid < handle
   
    properties
        id
    end
    
    methods (Static)
        function guid = NewGuid()
            id = java.util.UUID.randomUUID();
            guid = System.Guid(id);
        end
    end
    
    methods
        function obj = Guid(id)
            obj.id = id;
        end
        
        function s = ToString(obj)
            s = char(obj.id);
        end
    end
end