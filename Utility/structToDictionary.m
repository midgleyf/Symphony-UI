function d = structToDictionary(s)
    if ismac
        d = GenericDictionary();
    else
        d = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
    end
    keys = fieldnames(s);
    for i=1:length(keys)
        key = keys{i};
        d.Add(key, s.(key));
    end
end
