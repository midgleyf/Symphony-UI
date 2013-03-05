%    frameCount = GetFrameCount(myobj)
%
%                Returns the frame number of the current frame of the
%                currently running plugin. Calling this function without a
%                plugin currently running is unspecified, and will throw an
%                error.  

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetFrameCount(s)

    running = Running(s);
    if (isempty(running)),
        error('Cannot get frame count without a running plugin');
        return;
    end;
    ret = sscanf(DoQueryCmd(s, 'GETFRAMENUM'), '%d');
