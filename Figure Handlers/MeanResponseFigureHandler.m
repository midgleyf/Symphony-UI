classdef MeanResponseFigureHandler < FigureHandler
    
    properties (Constant)
        figureName = 'Mean Response'
    end
    
    properties
        meanPlots
    end
    
    methods
        
        function obj = MeanResponseFigureHandler(protocolPlugin)
            obj = obj@FigureHandler(protocolPlugin);
            
            xlabel(obj.axesHandle, 'sec');
            
            obj.resetPlots();
        end


        function handleCurrentEpoch(obj)
            [responseData, sampleRate, units] = obj.protocolPlugin.response();

            % Check if we have existing data for this "class" of epoch.
            % The class of the epoch is defined by the set of its unique parameters.
            epochParams = obj.protocolPlugin.epochSpecificParameters();
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
                meanPlot.params = epochParams;  % The params that define this class of epochs.
                meanPlot.data = responseData;
                meanPlot.sampleRate = sampleRate;
                meanPlot.units = units;
                meanPlot.count = 1;
                hold(obj.axesHandle, 'on');
                meanPlot.plotHandle = plot(obj.axesHandle, 1:numel(meanPlot.data), meanPlot.data);
                obj.meanPlots(end + 1) = meanPlot;

                duration = numel(meanPlot.data) / sampleRate;
                samplesPerTenth = sampleRate / 10;
                set(obj.axesHandle, 'XTick', 1:samplesPerTenth:numel(meanPlot.data), ...
                                    'XTickLabel', 0:.1:duration); % TODO: there could be more samples in a later epoch...
                ylabel(obj.axesHandle, units);
            else
                % This class of epoch has been seen before, add the current response to the mean.
                % TODO: Adjust response data to the same sample rate and unit as previous epochs if needed.
                meanPlot.data = (meanPlot.data * meanPlot.count + responseData) / (meanPlot.count + 1);
                meanPlot.count = meanPlot.count + 1;
                set(meanPlot.plotHandle, 'XData', 1:numel(meanPlot.data), ...
                                         'YData', meanPlot.data);
                obj.meanPlots(i) = meanPlot;
            end
        end
        
        
        function clearFigure(obj)
            obj.resetPlots();
            
            clearFigure@FigureHandler(obj);
        end
        
        
        function resetPlots(obj)
            obj.meanPlots = struct('params', {}, 'data', {}, 'sampleRate', {}, 'units', {}, 'count', {}, 'plotHandle', {});
        end
        
    end
    
end