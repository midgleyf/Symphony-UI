%    params = GetParams(myobj, 'PluginName')
%
%                Retrieve the configuration parameters (if any) for a
%                particular plugin.  Configuration parameters are a struct
%                of name/value pairs that plugins use to affect their
%                runtime operation. The returned structure may be empty if
%                no parameters have been set, or it may contain name/value
%                pairs corresponding to the configuration parameters of the
%                plugin in question. Note that each plugin maintains its
%                own set of configuration parameters, hence the need to
%                call GetParams specifying which plugin you are interested
%                in.
function [ret] = GetParams(s, plugin)

    if (~ischar(plugin)), error ('Plugin argument (argument 2) must be a string'); end;
    
    ret = struct();
    res = DoGetResultsCmd(s, sprintf('GETPARAMS %s', plugin));
    for i=1:length(res),
        [toks] = regexp(res{i}, '(\w+)\s*=\s*(.+)', 'tokens');
        if (size(toks,1)),
            a=toks{1};
            % optionally convert to numeric
            [matches] = regexp(a{2}, '^[0-9.e-, ]+$', 'match');
            if (~isempty(matches)),
                scn = sscanf(matches{1}, '%g');
                scn2 = sscanf(matches{1}, '%g, ');
                if (~isempty(scn2) & (isempty(scn) | (length(scn2) > length(scn)))), scn = scn2; end;
                if (~isempty(scn)), a{2} = scn; end;
            end; 
%            ret = setfield(ret, a{1}, a{2});
%            Use dynamic fieldnames instead
             ret.(a{1}) = a{2};
        end;
    end;
    
    