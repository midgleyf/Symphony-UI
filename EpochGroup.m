%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef EpochGroup < handle
    
    properties
        outputPath
        label
        keywords
        source
        identifier
        startTime
        userProperties = struct()
        
        parentGroup
        childGroups
    end
    
    methods
        
        function obj = EpochGroup(parentGroup, startTime)
            % Add to the group hierarchy.
            obj.parentGroup = parentGroup;
            if ~isempty(parentGroup)
                parentGroup.childGroups(end + 1) = obj;
            end
            obj.childGroups = EpochGroup.empty(1, 0);
            
            obj.identifier = System.Guid.NewGuid();
            obj.startTime = startTime;
        end
        
        
        function setUserProperty(obj, propName, propValue)
            obj.userProperties.(propName) = propValue;
        end
        
        
        function v = userProperty(obj, propName)
            v = obj.userProperties.(propName);
        end
        
        
        function g = rootGroup(obj)
            if isempty(obj.parentGroup)
                g = obj;
            else
                g = obj.parentGroup.rootGroup();
            end
        end
        
        
        function beginPersistence(obj, persistor)
            % Convert the keywords and properties to .NET equivalents.
            keywordsCA = strtrim(regexp(obj.keywords, ',', 'split'));
            if isequal(keywordsCA, {''})
                keywordsCA = {};
            end
            keywordsArray = NET.createArray('System.String', numel(keywordsCA));
            for i = 1:numel(keywordsCA)
                keywordsArray(i) = keywordsCA{i};
            end
            propertiesDict = structToDictionary(obj.userProperties);
            
            if isempty(obj.source)
                sourceString = '';
            else
                sourceString = char(obj.source.identifier.ToString());
            end
            persistor.BeginEpochGroup(obj.label, sourceString, keywordsArray, propertiesDict, obj.identifier, obj.startTime);
        end
        
        
        function endPersistence(obj, persistor) %#ok<MANU>
            persistor.EndEpochGroup();
        end
        
        
        function delete(obj)
            for i = 1:length(obj.childGroups)
                delete(obj.childGroups(i));
            end
        end
        
    end
    
end
