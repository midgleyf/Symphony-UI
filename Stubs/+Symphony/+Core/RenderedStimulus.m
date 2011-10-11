classdef RenderedStimulus < handle
   
    properties
        StimulusID
        Units
        Parameters
        Data
    end
    
    methods
        function obj = RenderedStimulus(identifier, units, parameters, data)
            obj = obj@handle();
            
            obj.StimulusID = identifier;
            obj.Units = units;
            obj.Parameters = parameters;
            obj.Data = data;
        end
        
        function d = Duration(obj)
            d = obj.Data.Duration;
        end
    end
    
end