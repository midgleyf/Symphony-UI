%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [ft, fz] = formatXMLDate(date)
    tz = java.util.TimeZone.getDefault();
    tzOffset = tz.getOffset(now);
    if tz.useDaylightTime
        tzOffset = tzOffset + tz.getDSTSavings();
    end
    tzOffset = tzOffset / 1000 / 60;
    ft = [datestr(date, 'mm/dd/yyyy HH:MM:SS PM') sprintf(' %+03d:%02d', tzOffset / 60, mod(tzOffset, 60))];
    fz = tz.getDisplayName(tz.useDaylightTime, java.util.TimeZone.LONG);
end
