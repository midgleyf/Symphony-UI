%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    version = GetVersion(myobj)
%
%                Obtain the version string associated with the
%                SimulateOpenGL II process we are connected to.
function [ret] = GetVersion(s)

    ret = DoQueryCmd(s, 'GETVERSION');
