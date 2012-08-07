%    myobj = SetParams(myobj, 'PluginName', params_struct)
%
%                Set the configuration parameters for a particular plugin.
%                Configuration parameters are a struct of name/value pairs
%                that plugins use to affect their runtime operation.  The
%                structure specified here will completely replace the
%                existing struct (if any) that the plugin was using for its
%                configuration parameters.  Note that each plugin maintains
%                its own set of configuration parameters, hence the need to
%                call SetParams specifying the plugin name.  This call
%                cannot be made while the plugin in question is running,
%                because at that point the plugin may be actively using its
%                parameters and replacing them while it is running is not
%                defined.  Therefore, plugin parameters (if any) should be
%                set before the desired plugin is to be started.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [s] = SetParams(s, plugin, params)
    if (~ischar(plugin) | ~isstruct(params)),
        error('Arguments to stop are Stop(StimOpemGLOBJ, plugin_string, params_struct)');
    end;
    ChkConn(s);
    running = Running(s);
    if (strcmpi(running, plugin)),
        error('Cannot set params for a plugin while it''s running!  Stop() it first!');
    end;
    CalinsNetMex('sendString', s.handle, sprintf('SETPARAMS %s\n', plugin));
    ReceiveREADY(s, sprintf('SETPARAMS %s', plugin));
    names = fieldnames(params);
    for i=1:length(names),
        f = params.(names{i});
        if (isnumeric(f)),
            line = sprintf('%g ', f); % possibly vectorized print
            line = sprintf('%s = %s\n', names{i}, line);
        elseif (ischar(f)),
            line = sprintf('%s = %s\n', names{i}, f);
        else 
            error('Field %s must be numeric scalar or a string', names{i});
        end;
        CalinsNetMex('sendString', s.handle, line);
    end;
    % end with blank line
    CalinsNetMex('sendString', s.handle, sprintf('\n'));
    ReceiveOK(s);
    
    