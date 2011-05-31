classdef NET
   
    methods (Static)
        function obj = createArray(itemType, varargin)
            obj = NETArray(itemType, varargin{:});
        end
        
        function obj = createGeneric(itemType, varargin)
            if strcmp(itemType, 'System.Collections.Generic.Dictionary')
                obj = GenericDictionary();
            elseif strcmp(itemType, 'System.Collections.Generic.List')
                obj = GenericList();
            else
                error('Unknown generic type ''%s''', itemType);
            end
        end
    end
    
end