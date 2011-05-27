classdef Epoch < handle
   
    properties
        ProtocolID
        ProtocolParameters
        Stimuli
        Responses
        Identifier
        StartTime
    end
    
    methods
        function obj = Epoch(identifier, parameters)
            obj = obj@handle();
            
            obj.ProtocolID = identifier;
            if nargin == 2
                obj.ProtocolParameters = parameters;
            else
                obj.ProtocolParameters = GenericDictionary();
            end
            obj.Stimuli = GenericDictionary();
            obj.Responses = GenericDictionary();
            obj.Identifier = char(java.util.UUID.randomUUID());
        end
    end
    
end