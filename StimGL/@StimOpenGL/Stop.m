%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    myobj = Stop(myobj)
%    myobj = Stop(myobj, save_data_flag)
%   
%                Stop the currently running pluing (if any).  See Running.m
%                to determine which (if any) plugin is running.  Plugins
%                are silently unloaded immediately and no data is saved by
%                default.  However, the second version of this function,
%                taking the 'save_data_flag' specifies that plugin data
%                should be saved (if the flag is true).  Data is saved in 
%                the program 'SaveDir'.  The 'SaveDir' can be modified
%                using the SetSaveDir call.  It can be queried using the
%                GetSaveDir call.
function [s] = Stop(varargin)
    s = varargin{1};
    dosaveflag = 0;
    if (nargin > 1 & isnumeric(varargin{2})), dosaveflag = varargin{2}; end;
    if (~isnumeric(dosaveflag)),
        error('Arguments to stop are Stop(StimOpemGLOBJ, save_data_flag)');
    end;
    d = DoSimpleCmd(s, sprintf('STOP %d', dosaveflag));
    i=0;
    while (length(Running(s)) & i < 6),
        pause(.5);
        i=i+1;
    end;
    

    