%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function values = listValues(list)
    if iscell(list)
        values = list;
    else
        values = cell(1, list.Count);
        enum = list.GetEnumerator();
        i = 1;
        while enum.MoveNext()
            values{i} = enum.Current();
            i = i + 1;
        end
    end
end
