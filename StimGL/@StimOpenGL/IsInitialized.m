%    boolval = IsInitialized(myobj)
%
%                Determine if the running plugin (if any) is currently in 
%                the 'initialized' or 'uninitialized' state.  Returns a
%                true value if the plugin has finished initializing. When a
%                plugin is first started, it remains in the uninitialized
%                state until initialization finishes (usually under 1
%                second after it is started). 

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [ret] = IsInitialized(s)

    ret = sscanf(DoQueryCmd(s, 'ISINITIALIZED'), '%d');
