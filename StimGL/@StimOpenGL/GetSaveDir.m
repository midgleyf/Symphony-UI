%    dir = GetSaveDir(myobj)
%
%                Obtain the directory path to which data files will be
%                saved.  Data files are saved by plugins when they are
%                Stopped with the save_data_flag set to true.
function [ret] = GetSaveDir(s)

    ret = DoQueryCmd(s, 'GETSAVEDIR');
