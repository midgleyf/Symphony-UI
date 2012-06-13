%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    myobj = SetVSyncDisabled(myobj, disabled_flag)
%
%                Disables/enables VSync.  See also IsVSyncDisabled.m call.
%                This setting is persistent across runs of the program.
function [s] = SetVSyncDisabled(s, disabled_flag)

    if (~isnumeric(disabled_flag)), error('disabled_flag argument must be a boolean number'); end;
    DoSimpleCmd(s, sprintf('SETVSYNCDISABLED %d', disabled_flag));
    