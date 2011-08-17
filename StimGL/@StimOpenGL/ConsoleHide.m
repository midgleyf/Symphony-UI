%    myobj = ConsoleHide(myobj)
%
%                Hides the StimulateOpenGL II console window.  This may be
%                useful in order to unclutter the desktop or as a
%                performance optimization, since the console window may
%                theoretically interfere with the GL window's framerate.
function [s] = ConsoleHide(s)

    s = DoSimpleCmd(s, 'CONSOLEHIDE');
