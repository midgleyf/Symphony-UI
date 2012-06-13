%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    myobj = ConsoleHide(myobj)
%
%                Hides the StimulateOpenGL II console window.  This may be
%                useful in order to unclutter the desktop or as a
%                performance optimization, since the console window may
%                theoretically interfere with the GL window's framerate.
function [s] = ConsoleHide(s)

    s = DoSimpleCmd(s, 'CONSOLEHIDE');
