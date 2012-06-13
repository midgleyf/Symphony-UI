%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!
function [res] = DoQueryCmd(sm, cmd)

  ChkConn(sm);
  res = CalinsNetMex('sendstring', sm.handle, sprintf('%s\n', cmd));
  if (isempty(res)), error('%s error, cannot send string!', cmd); end;
  lines = CalinsNetMex('readlines', sm.handle);
  if (isempty(lines)), error('%s error, empty result! Is the connection down?', cmd); end;
  [m, n] = size(lines);
  respos = 1;
  if (m == 2), respos = 2; end;
  if (~isempty(findstr(lines(respos, 1:n), 'ERROR'))), error('Unexpected response from server on query command %s', cmd); 
  elseif (m ~= 2 | isempty(findstr(lines(2,1:n), 'OK')) ), ReceiveOK(sm, cmd); end; %error(sprintf('%s result status is not OK.', cmd)); end;
  if (m < 1 | isempty(lines)), error('Unexpected response from server on query command %s', cmd); end;
  res = lines(1,1:n);


