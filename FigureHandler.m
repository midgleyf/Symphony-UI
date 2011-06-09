classdef FigureHandler < handle
    
    properties (Constant, Abstract)
        figureName
    end
    
    properties
        protocolPlugin
        figureHandle
        axesHandle
    end
    
    events
        FigureClosed
    end
    
    methods
        
        function obj = FigureHandler(protocolPlugin)
            obj = obj@handle();
            
            obj.protocolPlugin = protocolPlugin;
            
            % Restore the previous window position.
            prefName = [class(obj) '_Position'];
            if ispref('Symphony', prefName)
                addlProps = {'Position', getpref('Symphony', prefName)};
            else
                addlProps = {};
            end
            
            obj.figureHandle = figure('Name', [protocolPlugin.displayName ': ' obj.figureName], ...
                                'NumberTitle', 'off', ...
                                'Toolbar', 'none', ...
                                'CloseRequestFcn', @(source, event)closeRequestFcn(obj, source, event), ...
                                addlProps{:});
            obj.axesHandle = axes('Position', [0.1 0.1 0.85 0.85]);
        end
        
        
        function clearFigure(obj)
            set(get(obj.axesHandle, 'Title'), 'String', '');
            cla(obj.axesHandle);
        end
        
        
        function close(obj)
            if ~isempty(obj.figureHandle)
                close(obj.figureHandle);
            end
        end
        
        
        function closeRequestFcn(obj, ~, ~)
            % Remember the window position.
            prefName = [class(obj) '_Position'];
            setpref('Symphony', prefName, get(obj.figureHandle, 'Position'));
            delete(obj.figureHandle);
            obj.figureHandle = [];
            
            notify(obj, 'FigureClosed');
        end
    end
    
    
    methods (Abstract)
        handleCurrentEpoch(obj);
    end
    
end