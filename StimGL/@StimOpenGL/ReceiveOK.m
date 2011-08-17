% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!
function [] = ReceiveOK(sm, cmd)
  lines = CalinsNetMex('readlines', sm.handle);
  [m,n] = size(lines);
  line = '';
  if (m & n),
      line = lines(1,1:n);
  end;
  if isempty(findstr('OK', line)),  
      errstr = sprintf('Server did not send OK after %s command.', cmd);
      if (m | n), errstr = sprintf('%s\nInstead it sent:\n\n >> %s', errstr, line); end;      
      error('%s\n', errstr); 
  end;

