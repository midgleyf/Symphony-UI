%    rate = GetRefreshRate(myobj)
%
%                Returns the refresh rate in Hz of the monitor that the
%                Open GL window is currently mostly sitting in.  Note that
%                moving the window to different monitors will cause this
%                function to return updated values, so the returned value
%                is accurate and reliable and is the rate the plugin should
%                be using as it runs.
function [ret] = GetRefreshRate(s)

    ret = sscanf(DoQueryCmd(s, 'GETREFRESHRATE'), '%d');
