classdef DateTimeOffset
   
    properties
        dateTime
    end
    
    methods (Static)
        function dto = Now()
            dto = System.DateTimeOffset(now);
        end
    end
    
    methods
        
        function obj = DateTimeOffset(dateTime)
            obj.dateTime = dateTime;
        end
        
        function s = ToString(obj)
            tz = java.util.TimeZone.getDefault();
            tzOffset = tz.getOffset(obj.dateTime);
            if tz.useDaylightTime
                tzOffset = tzOffset + tz.getDSTSavings();
            end
            tzOffset = tzOffset / 1000 / 60;
            s = [datestr(date, 'mm/dd/yyyy HH:MM:SS PM') sprintf(' %+03d:%02d', tzOffset / 60, mod(tzOffset, 60))];
        end
        
    end
end