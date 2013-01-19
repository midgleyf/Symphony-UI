%    stats = GetFrameVars(myobj)
%                
%                Get frame vars command.  Returns an MxN array of doubles
%                which are the frame vars for the last plugin that ran
%                successfully.  Each row represents one frame (or 1 of 3
%                grayplanes in quad-frame mode).  The frame var columns of
%                the row can be identified by looking at the results
%                returns from the GetFrameVarNames.m method.  As of the
%                time of this writing, only two plugins support frame vars:
%                MovingObject and MovingGrating.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetFrameVars(s)
   ret = DoQueryMatrixCmd(s, 'GETFRAMEVARS');
    
    
    
    
