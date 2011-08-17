%    version = GetVersion(myobj)
%
%                Obtain the version string associated with the
%                SimulateOpenGL II process we are connected to.
function [ret] = GetVersion(s)

    ret = DoQueryCmd(s, 'GETVERSION');
