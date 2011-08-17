% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!
function [res] = DoSimpleCmd(sm, cmd)

     ChkConn(sm);
     res = CalinsNetMex('sendstring', sm.handle, sprintf('%s\n', cmd));
     if (isempty(res)), error('Empty result for simple command %s, connection down?', cmd); end;
     ReceiveOK(sm, cmd);
     return;
end
