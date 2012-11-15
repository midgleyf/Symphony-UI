% Property Descriptions:
%
% DeviceName (string)
%   Name of the device containing the response to display. This value should be specified if more than one input
%   device is available. The default is the first input device name found (arbitrary).
%
% LineColor (ColorSpec)
%   Color of the response line. The default is blue.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef ResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Response'
    end
    
    properties
        plotHandle
        deviceName
        lineColor
    end
    
    methods
        
        function obj = ResponseFigureHandler(protocolPlugin, varargin)
            obj = obj@FigureHandler(protocolPlugin);
            
            ip = inputParser;
            ip.addParamValue('DeviceName', [], @(x)ischar(x));
            ip.addParamValue('LineColor', 'b', @(x)ischar(x) || isvector(x));
            ip.parse(varargin{:});
            
            obj.deviceName = ip.Results.DeviceName;
            obj.lineColor = ip.Results.LineColor;

            if ~isempty(obj.deviceName)
                set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName ' ' obj.figureType]);
            end   
                        
            obj.plotHandle = plot(obj.axesHandle(), 1:100, zeros(1, 100), 'Color', obj.lineColor);
            xlabel(obj.axesHandle(), 'sec');
            set(obj.axesHandle(), 'XTickMode', 'auto'); 
        end
        
        
        function handleCurrentEpoch(obj)
            % Update the figure title with the epoch number and any parameters that are different from the protocol default.
            epochParams = obj.protocolPlugin.epochSpecificParameters();
            paramsText = '';
            if ~isempty(epochParams)
                for field = sort(fieldnames(epochParams))'
                    paramValue = epochParams.(field{1});
                    if islogical(paramValue)
                        if paramValue
                            paramValue = 'True';
                        else
                            paramValue = 'False';
                        end
                    elseif isnumeric(paramValue)
                        paramValue = num2str(paramValue);
                    end
                    paramsText = [paramsText ', ' humanReadableParameterName(field{1}) ' = ' paramValue]; %#ok<AGROW>
                end
            end
            set(get(obj.axesHandle(), 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.epochNum) paramsText]);

            if isempty(obj.deviceName)
                % Use the first device response found if no device name is specified.
                [responseData, sampleRate, units] = obj.protocolPlugin.response();
            else
                [responseData, sampleRate, units] = obj.protocolPlugin.response(obj.deviceName);
            end
            
            % Plot the response
            if isempty(responseData)
                text(0.5, 0.5, 'no response data available', 'FontSize', 12, 'HorizontalAlignment', 'center');
            else
                set(obj.plotHandle, 'XData', (1:numel(responseData))/sampleRate, ...
                                    'YData', responseData);
                ylabel(obj.axesHandle(), units);
            end
        end
        
        
        function clearFigure(obj)
            clearFigure@FigureHandler(obj);
            
            obj.plotHandle = plot(obj.axesHandle(), 1:100, zeros(1, 100), 'Color', obj.lineColor);
        end
        
    end
    
end