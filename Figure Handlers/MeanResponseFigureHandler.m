% Property Descriptions:
%
% DeviceName (string)
%   Name of the device containing the response to average. This value should be specified if more than one input
%   device is available. The default is the first input device name found (arbitrary).
%
% LineColor (ColorSpec)
%   Color of the mean response line. The default is blue.
%
% GroupByParams (string | cell array of strings)
%   List of epoch parameters whose values are used to group mean responses. The default is all current epoch parameters.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef MeanResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Mean Response'
    end
    
    properties
        deviceName
        lineColor
        meanPlots   % array of structures to store the properties of each class of epoch.
        meanParamNames
    end
    
    methods
        
        function obj = MeanResponseFigureHandler(protocolPlugin, varargin)
            obj = obj@FigureHandler(protocolPlugin);
            
            ip = inputParser;
            ip.addParamValue('DeviceName', [], @(x)ischar(x));
            ip.addParamValue('LineColor', 'b', @(x)ischar(x) || isvector(x));
            ip.addParamValue('GroupByParams', {}, @(x)iscell(x) || ischar(x));
            ip.parse(varargin{:});
            
            obj.deviceName = ip.Results.DeviceName;
            obj.lineColor = ip.Results.LineColor;
            
            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end 
            
            if iscell(ip.Results.GroupByParams)
                obj.meanParamNames = ip.Results.GroupByParams;
            else
                obj.meanParamNames = {ip.Results.GroupByParams};
            end
                  
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto');
            
            obj.resetPlots();
        end
        
        
        function handleCurrentEpoch(obj)
            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = obj.protocolPlugin.response();
            else
                [responseData, sampleRate, units] = obj.protocolPlugin.response(obj.deviceName);
            end
            
            % Get the parameters for this "class" of epoch.
            % An epoch class is defined by a set of parameter values.
            if isempty(obj.meanParamNames)
                % Automatically detect the set of parameters.
                epochParams = obj.protocolPlugin.epochSpecificParameters();
            else
                % The protocol has specified which parameters to use.
                for i = 1:length(obj.meanParamNames)
                    epochParams.(obj.meanParamNames{i}) = obj.protocolPlugin.epoch.ProtocolParameters.Item(obj.meanParamNames{i});
                end
            end
            
            % Check if we have existing data for this class of epoch.
            meanPlot = struct([]);
            for i = 1:numel(obj.meanPlots)
                if isequal(obj.meanPlots(i).params, epochParams)
                    meanPlot = obj.meanPlots(i);
                    break;
                end
            end
            
            if isempty(meanPlot)
                % This is the first epoch of this class to be plotted.
                meanPlot = {};
                meanPlot.params = epochParams;
                meanPlot.data = responseData;
                meanPlot.sampleRate = sampleRate;
                meanPlot.units = units;
                meanPlot.count = 1;
                hold(obj.axesHandle(), 'on');
                meanPlot.plotHandle = plot(obj.axesHandle(), (1:length(meanPlot.data)) / sampleRate, meanPlot.data, 'Color', obj.lineColor);
                obj.meanPlots(end + 1) = meanPlot;
            else
                % This class of epoch has been seen before, add the current response to the mean.
                % TODO: Adjust response data to the same sample rate and unit as previous epochs if needed.
                % TODO: if the length of data is varying then the mean will not be correct beyond the min length.
                meanPlot.data = (meanPlot.data * meanPlot.count + responseData) / (meanPlot.count + 1);
                meanPlot.count = meanPlot.count + 1;
                set(meanPlot.plotHandle, 'XData', (1:length(meanPlot.data)) / sampleRate, ...
                                         'YData', meanPlot.data);
                obj.meanPlots(i) = meanPlot;
            end
            
            % Update the y axis with the units of the response.
            ylabel(obj.axesHandle(), units);
            
            if isempty(epochParams)
                titleString = 'All epochs grouped together.';
            else
                paramNames = fieldnames(epochParams);
                titleString = ['Grouped by ' humanReadableParameterName(paramNames{1})];
                for i = 2:length(paramNames) - 1
                    titleString = [titleString ', ' humanReadableParameterName(paramNames{i})];
                end
                if length(paramNames) > 1
                    titleString = [titleString ' and ' humanReadableParameterName(paramNames{end})];
                end
            end
            title(obj.axesHandle(), titleString);
        end
        
        
        function clearFigure(obj)
            obj.resetPlots();
            
            clearFigure@FigureHandler(obj);
        end
        
        
        function resetPlots(obj)
            obj.meanPlots = struct('params', {}, ...        % The params that define this class of epochs.
                                   'data', {}, ...          % The mean of all responses of this class.
                                   'sampleRate', {}, ...    % The sampling rate of the mean response.
                                   'units', {}, ...         % The units of the mean response.
                                   'count', {}, ...         % The number of responses used to calculate the mean reponse.
                                   'plotHandle', {});       % The handle of the plot for the mean response of this class.
        end
        
    end
    
end