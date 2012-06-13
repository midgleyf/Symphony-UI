%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function hrn = humanReadableParameterName(n)
    hrn = regexprep(n, '([^A-Z])([A-Z])', '$1 $2');
    hrn = regexprep(hrn, '([A-Z])([A-Z])', '$1 $2');
    hrn = strrep(hrn, '_', ' ');
    hrn(1) = upper(hrn(1));
end
