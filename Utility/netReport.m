%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function r = netReport(netException)
    eObj = netException.ExceptionObject;
    r = char(eObj.Message);
    indent = '    ';
    while ~isempty(eObj.InnerException)
        eObj = eObj.InnerException;
        r = [r char(10) indent char(eObj.Message)]; %#ok<AGROW>
        indent = [indent '    ']; %#ok<AGROW>
    end
end
