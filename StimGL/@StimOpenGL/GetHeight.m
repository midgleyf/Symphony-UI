%    height = GetHeight(myobj)
%
%                Returns the height of the Open GL window in pixels.
function [ret] = GetHeight(s)

    ret = sscanf(DoQueryCmd(s, 'GETHEIGHT'), '%d');