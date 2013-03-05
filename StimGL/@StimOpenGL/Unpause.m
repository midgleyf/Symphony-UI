%    myobj = Unpause(myobj)
%
%                The opposite of pause -- resumes execution of the
%                currently-running plugin. Pausing/unpausing only makes
%                sense if there *is* a currently-running plugin.  Unpaused
%                plugins continue to drawn new frames as normal, as if they
%                were never paused.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [s] = Unpause(s)

    s = DoSimpleCmd(s, 'UNPAUSE');
