%    myobj = ConsoleUnhide(myobj)
%
%                Unhides the StimulateOpenGL II console window, causing it
%                to be shown again.  See also ConsoleHide and
%                IsConsoleHidden.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [s] = ConsoleUnhide(s)

    s = DoSimpleCmd(s, 'CONSOLEUNHIDE');
