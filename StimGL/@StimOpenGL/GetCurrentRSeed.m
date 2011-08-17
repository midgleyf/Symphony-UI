%    height = GetCurrentRSeed(myobj)
%
%                Returns the current random number generator seed used by 
%                the plugin.  Useful for rndtrial=1 with MovingObjects
function [ret] = GetCurrentRSeed(s)

    ret = sscanf(DoQueryCmd(s, 'GETCURRENTRSEED'), '%d');