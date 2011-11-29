classdef ResponseStatisticsFigureHandler < FigureHandler
    
    properties (Constant)
        figureType = 'Response Statistics'
        plotColors = 'rbykmc';
    end
    
    properties
        statsCallback
        statPlots
    end
    
    methods
        
        function obj = ResponseStatisticsFigureHandler(protocolPlugin, varargin)
            obj = obj@FigureHandler(protocolPlugin);
            
            ip = inputParser;
            ip.addParamValue('StatsCallback', [], @(x)isa(x, 'function_handle'));
            ip.parse(varargin{:});
            
            if isempty(ip.Results.StatsCallback)
                obj.close();
                error 'The StatsCallback parameter must be supplied for Response Statistics figures.'
            end
            
            obj.statsCallback = ip.Results.StatsCallback;
            
            xlabel(obj.axesHandle(), 'epoch');
            hold(obj.axesHandle(), 'on');
            
            obj.statPlots = struct;
        end


        function handleCurrentEpoch(obj)
            % Ask the callback for the statistics
            stats = obj.statsCallback(obj.protocolPlugin);
            
            statNames = fieldnames(stats);
            for i = 1:numel(statNames)
                statName = statNames{i};
                stat = stats.(statName);

                if isfield(obj.statPlots, statName)
                    obj.statPlots.(statName).xData(end + 1) = obj.protocolPlugin.epochNum;
                    obj.statPlots.(statName).yData(end + 1) = stat;
                    set(obj.statPlots.(statName).plotHandle, 'XData', obj.statPlots.(statName).xData, ...
                                                             'YData', obj.statPlots.(statName).yData);
                else
                    statPlot = {};
                    statPlot.xData = obj.protocolPlugin.epochNum;
                    statPlot.yData = stat;
                    plotColor = ResponseStatisticsFigureHandler.plotColors(numel(fieldnames(obj.statPlots)) + 1);
                    statPlot.plotHandle = plot(obj.axesHandle(), statPlot.xData, statPlot.yData, 'o', ...
                                               'MarkerEdgeColor', plotColor, ...
                                               'MarkerFaceColor', plotColor);
                    obj.statPlots.(statName) = statPlot;
                end
                
                set(obj.axesHandle(), 'XTick', 1:obj.protocolPlugin.epochNum, ...
                                      'XLim', [0.5 obj.protocolPlugin.epochNum + 0.5]);
            end
        end
        
        
        function clearFigure(obj)
            obj.statPlots = struct;
            
            clearFigure@FigureHandler(obj);
        end
        
    end
    
end