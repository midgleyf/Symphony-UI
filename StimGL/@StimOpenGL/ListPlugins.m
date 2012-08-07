%    plugs = ListPlugins(myobj)
%        
%                List plugins command.  Lists all the plugins that are
%                loaded in memory.  All plugins in this list can receive
%                'Start', 'Stop', 'GetParams' and 'SetParams' commands.
%                The returned data is a cell array of strings.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [res] = ListPlugins(s)

    res = DoGetResultsCmd(s, 'LIST');
    