%    myobj = Unpause(myobj)
%
%                The opposite of pause -- resumes execution of the
%                currently-running plugin. Pausing/unpausing only makes
%                sense if there *is* a currently-running plugin.  Unpaused
%                plugins continue to drawn new frames as normal, as if they
%                were never paused.
function [s] = Unpause(s)

    s = DoSimpleCmd(s, 'UNPAUSE');
