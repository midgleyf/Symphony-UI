% THIS FUNCTION IS PRIVATE AND SHOULD NOT BE CALLED BY OUTSIDE CODE!

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [res] = DoSimpleCmd(sm, cmd)

     ChkConn(sm);
     res = CalinsNetMex('sendstring', sm.handle, sprintf('%s\n', cmd));
     if (isempty(res)), error('Empty result for simple command %s, connection down?', cmd); end;
     ReceiveOK(sm, cmd);
     return;
end
