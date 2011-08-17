%    myobj = Close(myobj)
%
%                Closes the network connection to the StimulateOpenGL II
%                process. Useful only to cleanup resources when you are
%                done with a connection to StimulateOpenGL II.
function [s] = Close(s)
    CalinsNetMex('disconnect', s.handle);
%    CalinsNetMex('destroy', s.handle);
    s.handle = -1;
