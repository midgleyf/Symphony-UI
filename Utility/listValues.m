function values = listValues(list)
    if iscell(list)
        values = list;
    else
        values = cell(1, list.Count);
        enum = list.GetEnumerator();
        i = 1;
        while enum.MoveNext()
            values{i} = enum.Current();
            i = i + 1;
        end
    end
end
