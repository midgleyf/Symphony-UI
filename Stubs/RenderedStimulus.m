classdef RenderedStimulus < handle
   
    properties
        StimulusID
        Parameters
        Data
    end
    
    methods
        function obj = RenderedStimulus(identifier, parameters, data)
            obj = obj@handle();
            
            obj.StimulusID = identifier;
            obj.Parameters = parameters;
            obj.Data = data;
        end
        
        function d = Duration(obj)
            d = obj.Data.Duration;
        end
    end
    
end