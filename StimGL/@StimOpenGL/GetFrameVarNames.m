%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    cell_array_of_strings = GetFrameVarNames(myobj)
%                
%                Retrieves the names of the frame vars.  Returns an Mx1 cell array
%                of strings.  Each string represents the name of a frame
%                var field as returned from GetFrameVars.  
%                See GetFrameVars.m to retrieve the frame vars themselves.
function [ret] = GetFrameVarNames(s)
    res = DoGetResultsCmd(s, 'GETFRAMEVARNAMES');
    ret = res;
    
    
    
