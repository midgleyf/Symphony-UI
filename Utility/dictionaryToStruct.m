%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function s = dictionaryToStruct(d)
    s = {};
    
    if isa(d, 'GenericDictionary')
        keys = d.Keys;
    else
        keys = {};
        dictKeys = d.Keys.GetEnumerator();
        while dictKeys.MoveNext()
            keys{end + 1} = char(dictKeys.Current()); %#ok<AGROW>
        end
    end
    
    for key = keys
        value = d.Item(key{1});
        if isa(value, 'System.String')
            value = char(value);
        end
        s.(key{1}) = value;
    end
end
