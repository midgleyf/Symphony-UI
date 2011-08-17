%    boolval = IsConsoleHidden(myobj)
%
%                Determine if the console window is currently hidden or 
%                visible.  Returns true if the console window is hidden,
%                or false otherwise.  The console window may be
%                hidden/shown using the ConsoleHide() and ConsoleUnhide()
%                calls.
function [ret] = IsConsoleHidden(s)

    ret = sscanf(DoQueryCmd(s, 'ISCONSOLEHIDDEN'), '%d');
