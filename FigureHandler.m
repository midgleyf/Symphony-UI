classdef FigureHandler < handle
    
    properties (Constant, Abstract)
        figureName
    end
    
    properties
        protocolPlugin
        figureHandle
        axesHandle
    end
    
    methods
        
        function obj = FigureHandler(protocolPlugin)
            obj = obj@handle();
            
            obj.protocolPlugin = protocolPlugin;
            
            % TODO: persist window position
            
            obj.figureHandle = figure('Name', [protocolPlugin.displayName ': ' obj.figureName], ...
                                'NumberTitle', 'off', ...
                                'Toolbar', 'none');
            obj.axesHandle = axes('Position', [0.1 0.1 0.85 0.85]);
        end

    end
    
    
    methods (Abstract)
        handleCurrentEpoch(obj);
    end
    
end