% Property Descriptions:
%
% LineColor1 (ColorSpec)
%   Color of the device1 response line. The default is blue.
%
% LineColor2 (ColorSpec)
%   Color of the device2 response line. The default is red.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef DualResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Dual Response'
    end
    
    properties
        deviceName1
        lineColor1
        
        deviceName2
        lineColor2
    end
    
    methods
        
        function obj = DualResponseFigureHandler(protocolPlugin, deviceName1, deviceName2, varargin)            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addRequired('deviceName1', @(x)ischar(x)); 
            ip.addParamValue('LineColor1', 'b', @(x)ischar(x) || isvector(x));
            ip.addRequired('deviceName2', @(x)ischar(x)); 
            ip.addParamValue('LineColor2', 'r', @(x)ischar(x) || isvector(x));
            ip.parse(deviceName1, deviceName2, varargin{:});
            
            obj = obj@FigureHandler(protocolPlugin, ip.Unmatched);
            obj.deviceName1 = ip.Results.deviceName1;
            obj.lineColor1 = ip.Results.LineColor1;
            obj.deviceName2 = ip.Results.deviceName2;
            obj.lineColor2 = ip.Results.LineColor2;          
            
            set(obj.figureHandle, 'Name', [obj.protocolPlugin.displayName ': ' obj.deviceName1 ' & ' obj.deviceName2 ' ' obj.figureType]);
                  
            % The superclass axes cannot be used for plotyy.
            delete(obj.axesHandle());
            
            [axes, plotHandle1, plotHandle2] = plotyy(1:100, rand(1, 100), 1:100, zeros(1, 100));
            set(plotHandle1, 'Color', obj.lineColor1);
            set(axes(1), 'YColor', obj.lineColor1);
            set(plotHandle2, 'Color', obj.lineColor2);
            set(axes(2), 'YColor', obj.lineColor2);
            
            set(axes(1), 'Position', [0.1 0.1 0.8 0.85]);
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

            [responseData1, sampleRate1, units1] = obj.protocolPlugin.response(obj.deviceName1);
            [responseData2, sampleRate2, units2] = obj.protocolPlugin.response(obj.deviceName2);
            
            % Plot the response
            axes = obj.axes();
            x1 = (1:numel(responseData1))/sampleRate1;
            y1 = responseData1;
            x2 = (1:numel(responseData2))/sampleRate2;
            y2 = responseData2;
            [axes, plotHandle1, plotHandle2] = plotyy(axes(2), x1, y1, x2, y2);
            
            set(plotHandle1, 'Color', obj.lineColor1);
            set(axes(1), 'YColor', obj.lineColor1);
            set(get(axes(1), 'Ylabel'), 'String', units1);
            
            set(plotHandle2, 'Color', obj.lineColor2);
            set(axes(2), 'YColor', obj.lineColor2);
            set(get(axes(2), 'Ylabel'), 'String', units2);
            
            xlabel(axes(1), 'sec'); 
        end      
        
        
        function clearFigure(obj)
            clearFigure@FigureHandler(obj);
            
            axes = obj.axes();
            [axes, plotHandle1, plotHandle2] = plotyy(axes(2), 1:100, zeros(1, 100), 1:100, zeros(1, 100));
            set(plotHandle1, 'Color', obj.lineColor1);
            set(axes(1), 'YColor', obj.lineColor1);
            set(plotHandle2, 'Color', obj.lineColor2);
            set(axes(2), 'YColor', obj.lineColor2);
        end
        
    end
    
end

