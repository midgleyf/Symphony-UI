%    plugname = Running(myobj)
%
%                Determing which plugin, if any, is currently active and
%                running.  An active plugin is one for which 'Start' was
%                called but 'Stop' has not yet been called, or which has
%                not terminated on its own (plugins may terminate on their
%                own at any time, but at the time of this writing no
%                existing plugin does so).  Returns the plugin name that is
%                running as a string, or the empty string if no plugins are
%                running.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [ret] = Running(sm)

  ChkConn(sm);
  cmd = 'RUNNING';
  res = CalinsNetMex('sendstring', sm.handle, sprintf('%s\n', cmd));
  if (isempty(res)), error('%s error, cannot send string!', cmd); end;
  lines = CalinsNetMex('readlines', sm.handle);
  if (isempty(lines)), error('%s error, empty result! Is the connection down?', cmd); end;
  [m, n] = size(lines);
  respos = 1;
  if (m == 2), respos = 2; end;
  if (~isempty(findstr(lines(respos, 1:n), 'ERROR'))), 
      error('Unexpected response from server on query command %s', cmd); 
  end;
  if (m < 1 | isempty(lines)), warn('Unexpected response from server on query command %s', cmd); end;
  ret = lines(1,1:n);
  if (strcmp(ret, 'OK')) ret = ''; end;
  