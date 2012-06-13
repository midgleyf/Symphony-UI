%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function dn = classProperty(className, propertyName)
    mcls = meta.class.fromName(className);
    if isempty(mcls)
        dn = '';
    else
        % Get the type name
        props = mcls.PropertyList;
        for j = 1:length(props)
            prop = props(j);
            if strcmp(prop.Name, propertyName)
                dn = prop.DefaultValue;
                break;
            end
        end
    end
end
