%    boolval = IsVSyncDisabled(myobj)
%
%                Determine if the program frame renderer has VSync 
%                disabled or enabled (default returns false, or enabled). 
%                The program's VSync may be disabled with the
%                SetVSyncDisabled call.
function [ret] = IsVSyncDisabled(s)

    ret = sscanf(DoQueryCmd(s, 'ISVSYNCDISABLED'), '%d');
