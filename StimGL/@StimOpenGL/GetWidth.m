%    width = GetWidth(myobj)
%
%                Returns the width of the Open GL window in pixels.
function [ret] = GetWidth(s)

    ret = sscanf(DoQueryCmd(s, 'GETWIDTH'), '%d');