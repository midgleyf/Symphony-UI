%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function d = structDiff(s1, s2)
    d = {};
    
    f1 = fieldnames(s1);
    f2 = fieldnames(s2);
    newFields = setdiff(f1, f2);
    commonFields = intersect(f1, f2);
    
    for newField = {newFields{:}}
        d.(newField{1}) = s1.(newField{1});
    end
    for commonField = {commonFields{:}}
        if ~isequal(s1.(commonField{1}), s2.(commonField{1}))
            d.(commonField{1}) = s1.(commonField{1});
        end
    end
end
