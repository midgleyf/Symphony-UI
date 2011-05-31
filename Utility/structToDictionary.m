function d = structToDictionary(s)
    d = NET.createGeneric('System.Collections.Generic.Dictionary', {'System.String', 'System.Object'});
    keys = fieldnames(s);
    for i=1:length(keys)
        key = keys{i};
        d.Add(key, s.(key));
    end
end
