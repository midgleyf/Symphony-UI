function hrn = humanReadableParameterName(n)
    hrn = regexprep(n, '([^A-Z])([A-Z])', '$1 $2');
    hrn = regexprep(hrn, '([A-Z])([A-Z])', '$1 $2');
    hrn = strrep(hrn, '_', ' ');
    hrn(1) = upper(hrn(1));
end
