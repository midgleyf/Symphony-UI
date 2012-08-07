%    time = GetTime(myobj)
%
%                Returns the number of seconds since StimulateOpenGL II was
%                started.  The returned value has a resolution in the
%                nanoseconds range, since it comes from the CPU's timestamp
%                counter.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [ret] = GetTime(s)

    ret = sscanf(DoQueryCmd(s, 'GETTIME'), '%g');
