classdef EpochGroup < handle
    
    properties
        outputPath
        parentLabel
        label
        keywords
        source
        userProperties = struct()
    end
    
    methods
        
        function setUserProperty(obj, propName, propValue)
            obj.userProperties.(propName) = propValue;
        end
        
        function v = userProperty(obj, propName)
            v = obj.userProperties.(propName);
        end
        
    end
    
end
