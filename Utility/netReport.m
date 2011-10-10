function r = netReport(netException)
    eObj = netException.ExceptionObject;
    r = char(eObj.Message);
    indent = '    ';
    while ~isempty(eObj.InnerException)
        eObj = eObj.InnerException;
        r = [r char(10) indent char(eObj.Message)]; %#ok<AGROW>
        indent = [indent '    ']; %#ok<AGROW>
    end
end
