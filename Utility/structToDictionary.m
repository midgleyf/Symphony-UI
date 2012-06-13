%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function d = structToDictionary(s)
    d = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
    keys = fieldnames(s);
    for i=1:length(keys)
        key = keys{i};
        d.Add(key, s.(key));
    end
end
