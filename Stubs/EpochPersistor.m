classdef EpochPersistor < handle
   
    properties
    end
    
    methods (Abstract)
        BeginEpochGroup(obj, label, parents, sources, keywords, identifier);
        SerializeEpoch(obj, epoch);
        EndEpochGroup(obj);
        Close(obj);
    end
    
end