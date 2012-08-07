% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [mat] = DoQueryMatrixCmd(s, cmd)
    ChkConn(s);
    CalinsNetMex('sendString', s.handle, sprintf('%s\n', cmd));
    line = CalinsNetMex('readLine', s.handle);
    if (strfind(line, 'ERROR') == 1),
        error('Got ''%s'' reply for %s cmd', line, cmd);
        return;
    end;
    [DIMS,count,errmsg] = sscanf(line, 'MATRIX %d %d',[1,2]);
    if (isempty(DIMS)),
        error('Got empty MATRIX response for %s cmd', cmd);
        return;
    end;
    mat = zeros(0,DIMS(2));
    mat = CalinsNetMex('readMatrix', s.handle, 'double', DIMS);
    line = CalinsNetMex('readLine', s.handle);
    if (~(strfind(line, 'OK') == 1)),
        error('Did not get OK reply for %s cmd', cmd);
        mat = [];
        return;
    end;
    
