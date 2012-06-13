%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    boolval = IsConsoleHidden(myobj)
%
%                Determine if the console window is currently hidden or 
%                visible.  Returns true if the console window is hidden,
%                or false otherwise.  The console window may be
%                hidden/shown using the ConsoleHide() and ConsoleUnhide()
%                calls.
function [ret] = IsConsoleHidden(s)

    ret = sscanf(DoQueryCmd(s, 'ISCONSOLEHIDDEN'), '%d');
