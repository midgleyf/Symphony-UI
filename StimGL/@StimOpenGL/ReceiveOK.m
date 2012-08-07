% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

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

