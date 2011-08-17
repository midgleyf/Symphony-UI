%    myobj = SetVSyncDisabled(myobj, disabled_flag)
%
%                Disables/enables VSync.  See also IsVSyncDisabled.m call.
%                This setting is persistent across runs of the program.
function [s] = SetVSyncDisabled(s, disabled_flag)

    if (~isnumeric(disabled_flag)), error('disabled_flag argument must be a boolean number'); end;
    DoSimpleCmd(s, sprintf('SETVSYNCDISABLED %d', disabled_flag));
    