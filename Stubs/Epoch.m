classdef Epoch < handle
   
    properties
        ProtocolID
        ProtocolParameters
        Stimuli
        Responses
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
        end
    end
    
end