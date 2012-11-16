% Property Descriptions:
%
% ID (valid variable name)
%   Identifier for saving and loading window positions. The default saves a single window position for all figure
%   handlers of the same class. A unique ID distinguishes two figure handlers of the same class and saves their window
%   positions separately.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef FigureHandler < handle
    
    properties (Constant, Abstract)
        figureType
    end
    
    properties
        protocolPlugin
        figureHandle
        id
    end
    
    events
        FigureClosed
    end
    
    methods
        
        function obj = FigureHandler(protocolPlugin, varargin)           
            ip = inputParser;
            ip.addParamValue('ID', [], @(x)isvarname(x));
            ip.parse(varargin{:});
            
            obj = obj@handle();
            obj.protocolPlugin = protocolPlugin;
            obj.id = ip.Results.ID;
            
            % Restore the previous window position.
            if isempty(obj.id)
                prefName = [class(obj) '_Position'];
            else
                prefName = [class(obj) '_' obj.id '_Position'];
            end
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
                if strcmp(get(child, 'Type'), 'axes') && ~strcmp(get(child, 'Tag'), 'Colorbar') && ~strcmp(get(child, 'Tag'), 'legend')
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
            if isempty(obj.id)
                prefName = [class(obj) '_Position'];
            else
                prefName = [class(obj) '_' obj.id '_Position'];
            end
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