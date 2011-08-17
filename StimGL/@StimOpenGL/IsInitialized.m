%    boolval = IsInitialized(myobj)
%
%                Determine if the running plugin (if any) is currently in 
%                the 'initialized' or 'uninitialized' state.  Returns a
%                true value if the plugin has finished initializing. When a
%                plugin is first started, it remains in the uninitialized
%                state until initialization finishes (usually under 1
%                second after it is started). 
function [ret] = IsInitialized(s)

    ret = sscanf(DoQueryCmd(s, 'ISINITIALIZED'), '%d');
