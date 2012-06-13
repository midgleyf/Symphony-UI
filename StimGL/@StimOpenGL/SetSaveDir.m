%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    myobj = SetSaveDir(myobj, dir)
%
%                Specify directory path to which data files will be
%                saved.  Data files are saved by plugins when they are
%                Stopped with the save_data_flag set to true.  This setting
%                is persistent across runs of the program.
function [s] = SetSaveDir(s, dir)

    if (~ischar(dir)), error('dir argument must be a string'); end;
    DoSimpleCmd(s, sprintf('SETSAVEDIR %s', dir));
    