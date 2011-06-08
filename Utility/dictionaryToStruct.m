function s = dictionaryToStruct(d)
    s = {};
    
    if isa(d, 'GenericDictionary')
        keys = d.Keys;
    else
        keys = {};
        dictKeys = d.Keys.GetEnumerator();
        while dictKeys.MoveNext()
            keys{end + 1} = char(dictKeys.Current()); %#ok<AGROW>
        end
    end
    
    for key = keys
        s.(key{1}) = d.Item(key{1});
    end
end
