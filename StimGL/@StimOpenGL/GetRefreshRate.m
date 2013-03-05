%    rate = GetRefreshRate(myobj)
%
%                Returns the refresh rate in Hz of the monitor that the
%                Open GL window is currently mostly sitting in.  Note that
%                moving the window to different monitors will cause this
%                function to return updated values, so the returned value
%                is accurate and reliable and is the rate the plugin should
%                be using as it runs.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetRefreshRate(s)

    ret = sscanf(DoQueryCmd(s, 'GETREFRESHRATE'), '%d');
