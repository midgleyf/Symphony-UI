function obj = createGeneric(itemType, varargin)
    if strcmp(itemType, 'System.Collections.Generic.Dictionary')
        obj = GenericDictionary();
    elseif strcmp(itemType, 'System.Collections.Generic.List')
        obj = GenericList(varargin{:});
    else
        error('Unknown generic type ''%s''', itemType);
    end
end
