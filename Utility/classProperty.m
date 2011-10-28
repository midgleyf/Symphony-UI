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
