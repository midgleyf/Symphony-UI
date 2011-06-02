function d = structDiff(s1, s2)
    d = {};
    
    f1 = fieldnames(s1);
    f2 = fieldnames(s2);
    newFields = setdiff(f1, f2);
    commonFields = intersect(f1, f2);
    
    for newField = {newFields{:}}
        d.(newField{1}) = s1.(newField{1});
    end
    for commonField = {commonFields{:}}
        if ~isequal(s1.(commonField{1}), s2.(commonField{1}))
            d.(commonField{1}) = s1.(commonField{1});
        end
    end
end
