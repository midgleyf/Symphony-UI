classdef Guid
   
    methods (Static)
        function id = NewGuid()
            id = char(java.util.UUID.randomUUID());
        end
    end
end