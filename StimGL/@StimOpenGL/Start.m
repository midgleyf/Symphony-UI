%    myobj = Start(myobj, 'PluginName')
%    myobj = Start(myobj, 'PluginName', start_unpaused_flag)
%
%                Start a plugin by name.  The string 'PluginName' must be a 
%                valid plugin as exists in the list obainted from the 
%                ListPlugins command.   Plugins typically also take a set
%                of parameters.  The parameters the plugin uses are the
%                ones extant at the time of this call, having been
%                optionally previously specified with the SetParams command
%                (see SetParams.m).  By default plugins start in a 'paused'
%                state but they may be told to start unpaused, in which
%                case the 3-argument version of this function may be used,
%                setting start_unpaused_flag to true (1).

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [s] = Start(varargin)
    s = varargin{1};
    pluginname = '';
    startunpaused = 0;
    if (nargin <= 1), 
        error('Please supply a plugin name as arg 2.');
    end;
    if (nargin > 1), pluginname = varargin{2}; end;
    if (nargin > 2), startunpaused = varargin{3}; end;
    if (~ischar(pluginname) | ~isnumeric(startunpaused)),
        error('Arguments to start are Start(StimOpemGLOBJ, pluginString, startUnpausedFlag)');
    end;
    d = DoSimpleCmd(s, sprintf('START %s %d', pluginname, startunpaused));
    i=0;
    while (~IsInitialized(s) & i < 6),
        pause(.5);
        i=i+1;
    end;
    if (startunpaused),
        i=0;
        while (IsPaused(s) & i < 6),
            pause(.5);
            i=i+1;
        end;
    end;
    
