%    hwFrameCount = GetHWFrameCount(myobj)
%
%                Returns the number of frames that the video board has
%                drawn to the screen since some unspecified time in the
%                past.  The number returned is monotonically increasing and
%                does not require a currently running plugin.  It is
%                a count of the number of vblanks that the video board
%                has experienced since bootup.  However, on windows this
%                function is not supported natively and the obtained
%                framecount is unreliable at best.  Do not use on Windows.  
%                Repeat: 
%
%                DO NOT USE THIS FUNCTION FOR 'StimulateOpenGL II'
%                PROCESSES RUNNING ON WINDOWS!

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetHWFrameCount(s)

    ret = sscanf(DoQueryCmd(s, 'GETHWFRAMENUM'), '%d');
