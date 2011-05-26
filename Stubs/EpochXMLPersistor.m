classdef EpochXMLPersistor < EpochPersistor
   
    properties
        XMLPath
    end
    
    methods
        function obj = EpochXMLPersistor(xmlPath)
            obj = obj@EpochPersistor();
            
            obj.XMLPath = xmlPath;
        end
    end
    
end