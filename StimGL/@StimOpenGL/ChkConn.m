% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!
function [sm] = ChkConn(sm)
  if (sm.in_chkconn),  return;  end;
  if (sm.handle == -1), sm.handle = CalinsNetMex('create', sm.host, sm.port); end;
  ret = CalinsNetMex('sendstring', sm.handle, sprintf('NOOP\n'));
  if (isempty(ret) | isempty((CalinsNetMex('readlines', sm.handle))))
    ret = CalinsNetMex('connect', sm.handle);
    if (isempty(ret))
      error('Unable to connect to server.');
    end;
    sm.in_chkconn = 1;
  end;

