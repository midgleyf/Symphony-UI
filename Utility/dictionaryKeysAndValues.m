%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [keys, values] = dictionaryKeysAndValues(d)
    if isa(d, 'GenericDictionary')
        keys = d.Keys;
        values = d.Values;
    else
        keys = cell(1, d.Count);
        values = cell(1, d.Count);
        enum = d.Keys.GetEnumerator();
        i = 1;
        while enum.MoveNext()
            key = enum.Current();
            keys{i} = key;
            values{i} = d.Item(key);
            i = i + 1;
        end
    end
end
