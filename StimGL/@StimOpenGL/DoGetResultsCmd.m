% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!
function [res] = DoGetResultsCmd(s,cmd)

    ChkConn(s);
    CalinsNetMex('sendString', s.handle, sprintf('%s\n', cmd));
    line = [];
    res = cell(0,1);
    i = 0;
    while ( 1 ),        
        line = CalinsNetMex('readLine', s.handle);
        if (i == 0 & strfind(line, 'ERROR') == 1),
            error('Got ''%s'' reply for %s cmd', line, cmd);
            return;
        end;
        if (isempty(line)), continue; end;
        if (strcmp(line,'OK')), break; end;
        res = [ res; line ];
        i = i + 1;
    end;

