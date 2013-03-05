%    myobj = Close(myobj)
%
%                Closes the network connection to the StimulateOpenGL II
%                process. Useful only to cleanup resources when you are
%                done with a connection to StimulateOpenGL II.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [s] = Close(s)
    CalinsNetMex('disconnect', s.handle);
%    CalinsNetMex('destroy', s.handle);
    s.handle = -1;
