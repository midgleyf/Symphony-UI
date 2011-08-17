%    plugs = ListPlugins(myobj)
%        
%                List plugins command.  Lists all the plugins that are
%                loaded in memory.  All plugins in this list can receive
%                'Start', 'Stop', 'GetParams' and 'SetParams' commands.
%                The returned data is a cell array of strings.
function [res] = ListPlugins(s)

    res = DoGetResultsCmd(s, 'LIST');
    