classdef EpochPersistor < handle
   
    properties
    end
    
    methods (Abstract)
        BeginEpochGroup(obj, label, source, keywords, props, identifier, startTime);
        Serialize(obj, epoch);
        EndEpochGroup(obj);
        CloseDocument(obj);
    end
    
end