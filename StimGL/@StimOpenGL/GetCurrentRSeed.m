%    height = GetCurrentRSeed(myobj)
%
%                Returns the current random number generator seed used by 
%                the plugin.  Useful for rndtrial=1 with MovingObjects

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetCurrentRSeed(s)

    ret = sscanf(DoQueryCmd(s, 'GETCURRENTRSEED'), '%d');