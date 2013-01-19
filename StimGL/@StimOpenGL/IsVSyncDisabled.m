%    boolval = IsVSyncDisabled(myobj)
%
%                Determine if the program frame renderer has VSync 
%                disabled or enabled (default returns false, or enabled). 
%                The program's VSync may be disabled with the
%                SetVSyncDisabled call.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [ret] = IsVSyncDisabled(s)

    ret = sscanf(DoQueryCmd(s, 'ISVSYNCDISABLED'), '%d');
