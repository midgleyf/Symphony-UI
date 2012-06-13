%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    boolval = IsPaused(myobj)
%
%                Determine if the program is currently in the 'paused' or
%                'unpaused' state.  Returns true if the program is paused,
%                or false otherwise.  The program's paused state
%                may be modified with the Pause and Unpause calls.
function [ret] = IsPaused(s)

    ret = sscanf(DoQueryCmd(s, 'ISPAUSED'), '%d');
