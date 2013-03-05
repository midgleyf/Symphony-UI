%    stats = GetStats(myobj)
%                
%                Get stats command.  Retrieves a collection of various 
%                statistics and other general information. Note that some 
%                of the information returned here is obtainable via 
%                separate calls as well (the time via GetTime, program 
%                version via GetVersion, window dimensions via GetHeight 
%                and GetWidth, etc).  The returned data is a struct.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [stats] = GetStats(s)
    stats = struct();
    res = DoGetResultsCmd(s, 'GETSTATS');
    for i=1:length(res),
        [toks] = regexp(res{i}, '(\w+)\s*=\s*(.*)', 'tokens');
        if (size(toks,1)),
            a=toks{1};
            % optionally convert to numeric
            [matches] = regexp(a{2}, '^[0-9.e-]+$', 'match');
            if (~isempty(matches)),
                scn = sscanf(matches{1}, '%g');
                if (~isempty(scn)), a{2} = scn; end;
            end;            
%            stats = setfield(stats, a{1}, a{2});
            stats.(a{1}) = a{2}; 
        end;
    end;
    
