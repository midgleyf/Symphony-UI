%    time = GetTime(myobj)
%
%                Returns the number of seconds since StimulateOpenGL II was
%                started.  The returned value has a resolution in the
%                nanoseconds range, since it comes from the CPU's timestamp
%                counter.
function [ret] = GetTime(s)

    ret = sscanf(DoQueryCmd(s, 'GETTIME'), '%g');
