classdef Epoch < handle
   
    properties
        ProtocolID
        ProtocolParameters
        Stimuli
        Responses
    end
    
    methods
        function obj = Epoch(identifier)
            obj = obj@handle();
            
            obj.ProtocolID = identifier;
            obj.ProtocolParameters = GenericDictionary();
            obj.Stimuli = GenericDictionary();
            obj.Responses = GenericDictionary();
        end
    end
    
end