classdef FigureHandler < handle
    
    properties (Constant, Abstract)
        figureType
    end
    
    properties
        protocolPlugin
        figureHandle
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
            
            obj.figureHandle = figure('Name', [obj.protocolPlugin.displayName ': ' obj.figureType], ...
                                'NumberTitle', 'off', ...
                                'Toolbar', 'none', ...
                                'CloseRequestFcn', @(source, event)closeRequestFcn(obj, source, event), ...
                                addlProps{:});
            axes('Position', [0.1 0.1 0.85 0.85]);
        end
        
        
        function showFigure(obj)
            figure(obj.figureHandle);
        end
        
        
        function a = axes(obj)
            children = get(obj.figureHandle, 'Children');
            a = [];
            for i = 1:length(children)
                child = children(i);
                if strcmp(get(child, 'Type'), 'axes') && ~strcmp(get(child, 'Tag'), 'Colorbar')
                    a(end+1) = child; %#ok<AGROW>
                end
            end
        end
        
        
        function a = axesHandle(obj)
            axesList = obj.axes();
            if isempty(axesList)
                a = [];
            else
                a = axesList(1);
            end
        end
        
        
        function clearFigure(obj)
            axes = obj.axes();
            for i = 1:length(axes)
                set(get(axes(i), 'Title'), 'String', '');
                cla(axes(i));
            end
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