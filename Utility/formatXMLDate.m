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
