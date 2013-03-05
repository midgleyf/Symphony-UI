%    height = GetHeight(myobj)
%
%                Returns the height of the Open GL window in pixels.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetHeight(s)

    ret = sscanf(DoQueryCmd(s, 'GETHEIGHT'), '%d');