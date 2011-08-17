%    frameCount = GetFrameCount(myobj)
%
%                Returns the frame number of the current frame of the
%                currently running plugin. Calling this function without a
%                plugin currently running is unspecified, and will throw an
%                error.  
function [ret] = GetFrameCount(s)

    running = Running(s);
    if (isempty(running)),
        error('Cannot get frame count without a running plugin');
        return;
    end;
    ret = sscanf(DoQueryCmd(s, 'GETFRAMENUM'), '%d');
