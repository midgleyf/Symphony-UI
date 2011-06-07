classdef ResponseStatisticsFigureHandler < FigureHandler
    
    properties (Constant)
        figureName = 'Response Statistics'
        plotColors = 'rbykmc';
    end
    
    properties
        statPlots
    end
    
    methods
        
        function obj = ResponseStatisticsFigureHandler(protocolPlugin)
            obj = obj@FigureHandler(protocolPlugin);
            
            xlabel(obj.axesHandle, 'epoch');
            hold(obj.axesHandle, 'on');
            
            obj.statPlots = struct;
        end


        function handleCurrentEpoch(obj)
            % Ask the protocol plug-in for the statistics
            stats = obj.protocolPlugin.responseStatistics();
            
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
                    statPlot.plotHandle = plot(obj.axesHandle, statPlot.xData, statPlot.yData, 'o', ...
                                               'MarkerEdgeColor', plotColor, ...
                                               'MarkerFaceColor', plotColor);
                    obj.statPlots.(statName) = statPlot;
                end
            end
        end
        
        
        function clearFigure(obj)
            obj.statPlots = struct;
            
            clearFigure@FigureHandler(obj);
        end
        
    end
    
end