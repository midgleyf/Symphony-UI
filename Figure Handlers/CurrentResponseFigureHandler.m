classdef CurrentResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureName = 'Current Response'
    end
    
    properties
        plotHandle
    end
    
    methods
        
        function obj = CurrentResponseFigureHandler(protocolPlugin)
            obj = obj@FigureHandler(protocolPlugin);
            
            obj.plotHandle = plot(obj.axesHandle, 1:100, zeros(1, 100));
            xlabel(obj.axesHandle, 'sec');
        end


        function handleCurrentEpoch(obj)
            % Update the figure title with the epoch number and any parameters that are different from the protocol default.
            epochParams = obj.protocolPlugin.epochSpecificParameters();
            paramsText = '';
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
            set(get(obj.axesHandle, 'Title'), 'String', ['Epoch #' num2str(obj.protocolPlugin.epochNum) paramsText]);

            % Plot the response
            [responseData, sampleRate, units] = obj.protocolPlugin.response();
            duration = numel(responseData) / sampleRate;
            samplesPerTenth = sampleRate / 10;
            set(obj.plotHandle, 'XData', 1:numel(responseData), ...
                                'YData', responseData);
            set(obj.axesHandle, 'XTick', 1:samplesPerTenth:numel(responseData), ...
                                'XTickLabel', 0:.1:duration);
            ylabel(obj.axesHandle, units);
        end
        
        
        function clearFigure(obj)
            clearFigure@FigureHandler(obj);
            
            obj.plotHandle = plot(obj.axesHandle, 1:100, zeros(1, 100));
        end
        
    end
    
end