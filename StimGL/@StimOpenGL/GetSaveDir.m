%    dir = GetSaveDir(myobj)
%
%                Obtain the directory path to which data files will be
%                saved.  Data files are saved by plugins when they are
%                Stopped with the save_data_flag set to true.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ret] = GetSaveDir(s)

    ret = DoQueryCmd(s, 'GETSAVEDIR');
