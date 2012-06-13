%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef TempInt < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.TempInt'
        version = 1
        displayName = 't Integration'
    end
    
    properties (Hidden) % these properties are hidden
        plotData
        stimWave
        figureHandle
        axesHandle
    end
    
    properties
        stimDur = 5; %seconds
        preTime = 0.5; %seconds
        tailTime = 0.5; %seconds
        stimMean = 1; %LED output Volts (Scale factor?)
        stimStdDev = 2; %LED output Volts (Scale factor?)
        stimFreqCutOff = 60; %Hz
        stimFiltOrder = 4; %th
        STAwindow = 0.3; %sec
        continuousLight = 0.0; %LED output Volts (Scale factor?)
        preSynapticHold = -60; %mV
        numberOfAverages = uint8(10);
        interpulseInterval = 0.6; %seconds
        continuousRun = false;
        variableStim = false;
        spikePolThrLimRet = [Inf,0,100,0]; %spike detection default properties
    end
    
    methods
        
        function prepareRig(obj)
            % Call the base class method to set the DAQ sample rate.
            prepareRig@SymphonyProtocol(obj);
            
            % TODO: remove this once the base class is handling the sample rate
            %obj.rigConfig.sampleRate = obj.rigConfig.sampleRate;
            
            obj.setDeviceBackground('LED', obj.continuousLight, 'V');
            
            if strcmp(obj.rigConfig.multiClampMode('Amplifier_Ch1'), 'IClamp')
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-12, 'A');
            else
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-3, 'V');
            end
        end
        
        
        function prepareRun(obj)
            % Call the base class method which clears all figures.
            prepareRun@SymphonyProtocol(obj);
            
            % Prepare figures            
            sampInt = 1/obj.rigConfig.sampleRate;
            obj.plotData.time = sampInt:sampInt:obj.preTime+obj.stimDur+obj.tailTime;
            obj.openFigure('Custom','Name','ResponseFig','UpdateCallback',@updateResponseFig);
            obj.plotData.timeSTA = sampInt:sampInt:obj.STAwindow;
            obj.plotData.meanSTA= zeros(1,obj.rigConfig.sampleRate*obj.STAwindow);
            obj.plotData.numSpikes = 0;
            obj.openFigure('Custom','Name','MeanRespFig','UpdateCallback',@updateMeanRespFig);
            obj.stimWave = ones(1, (obj.rigConfig.sampleRate *(obj.preTime + obj.stimDur + obj.tailTime))) * obj.continuousLight; 
 
        end

        
        function updateResponseFig(obj,axesHandle) %figure Response
            data = obj.response('Amplifier_Ch1');
            %plot Response
            subplot(15,1,2:11)

            if obj.epochNum==1
                obj.plotData.responseLineHandle = line(obj.plotData.time,data,'Color','k'); 
                % plot DATA
                obj.plotData.spikeMarkerHandle = line(obj.plotData.time(obj.plotData.spikePts),data(obj.plotData.spikePts),'Color','g','Marker','o','LineStyle','none');
                % plot Spike Points
                xlabel('s');
               % ylabel('pA');  % make it dependant on recording modde
                set(0, 'CurrentFigure', obj.figureHandle);
                set(obj.figureHandle, 'CurrentAxes', obj.axesHandle);
                set(obj.axesHandle,'Box','off','TickDir','out','Position',[0.1 0.1 0.9 0.8]);
                obj.plotData.epochCountHandle = uicontrol('Style','text','Units','normalized','Position',[0.25 0.96 0.5 0.03],'FontWeight','bold');
                uicontrol('Style','text','Units','normalized','Position',[0.17 0.915 0.075 0.03],'String','polarity');
                obj.plotData.polarityEditHandle = uicontrol('Style','edit','Units','normalized','Position',[0.255 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(1)));
                uicontrol('Style','text','Units','normalized','Position',[0.35 0.915 0.075 0.03],'String','thresh');
                obj.plotData.threshEditHandle = uicontrol('Style','edit','Units','normalized','Position',[0.435 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(2)));
                uicontrol('Style','text','Units','normalized','Position',[0.53 0.915 0.075 0.03],'String','limit');
                obj.plotData.limitEditHandle = uicontrol('Style','edit','Units','normalized','Position',[0.615 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(3)));
                uicontrol('Style','text','Units','normalized','Position',[0.71 0.915 0.075 0.03],'String','return');
                obj.plotData.returnEditHandle = uicontrol('Style','edit','Units','normalized','Position',[0.795 0.905 0.075 0.05],'String',num2str(obj.spikePolThrLimRet(4)));
            else
                set(0, 'CurrentFigure', obj.figureHandle);
                set(obj.figureHandle, 'CurrentAxes', obj.axesHandle);
                set(obj.plotData.responseLineHandle,'Ydata',data);
                set(obj.plotData.spikeMarkerHandle,'Xdata',obj.plotData.time(obj.plotData.spikePts),'Ydata',data(obj.plotData.spikePts));
            end
            
            %plot Stimulus
            subplot(15,1,13:15)
                if obj.epochNum==1
                   obj.plotData.stimulusLineHandle =line(obj.plotData.time,obj.stimWave,'Color','k');
                   xlabel('s');
                   ylabel('V');
                   set(0, 'CurrentFigure', obj.figureHandle);
                   set(obj.figureHandle, 'CurrentAxes', obj.axesHandle);
                   set(obj.axesHandle, 'Box','off','TickDir','out','Position',[0.2 0.2 0.85 0.8]);
                else
                    set(0, 'CurrentFigure', obj.figureHandle);
                    set(obj.figureHandle, 'CurrentAxes', obj.axesHandle);
                    set(obj.plotData.stimulusLineHandle,'Ydata',obj.stimWave);
                end          
                    set(obj.plotData.epochCountHandle,'String',['Epoch ' num2str(obj.epochNum) ' of ' num2str(obj.numberOfAverages)]);
        end
        
        function updateMeanRespFig(obj,axesHandle) %figure Mean
            if obj.epochNum==1
                obj.plotData.STAhandle = line(obj.plotData.timeSTA,obj.plotData.meanSTA,'Color','k');
                xlabel('s');
                ylabel('V');
                obj.plotData.SpikeCountHandle = uicontrol('Style','text','Units','normalized','Position',[0.25 0.96 0.5 0.03],'FontWeight','bold');          
            else
                set(0, 'CurrentFigure', obj.figureHandle);
                set(obj.figureHandle, 'CurrentAxes', obj.axesHandle);
                set(obj.plotData.STAhandle,'Ydata',obj.plotData.meanSTA);
            end
                set(obj.plotData.SpikeCountHandle,'String',[num2str(obj.plotData.numSpikes) ' spikes used on ' num2str(obj.epochNum) ' epochs']);
        end       
        
        
        function [stimulus , s] = stimulusForEpoch(obj, epochNum)
            % Determine the generated light amplitude
            r=obj.variableStim;
            if r==false
                s=rng('default');
                prebutter = randn(1,(obj.rigConfig.sampleRate * obj.stimDur)+100);
                fNorm = obj.stimFreqCutOff /(obj.rigConfig.sampleRate / 2);
                [b,a] = butter(obj.stimFiltOrder,fNorm,'low');
                preNorm = filtfilt(b,a,prebutter);
                lightAmplitude = obj.stimMean + obj.stimStdDev .*(preNorm / std(preNorm));
            else
                s=rng('shuffle');
                prebutter=randn(1,(obj.rigConfig.sampleRate * obj.stimDur)+100);
                fNorm = obj.stimFreqCutOff/(obj.rigConfig.sampleRate/2);
                [b,a] = butter(obj.stimFiltOrder,fNorm,'low');
                preNorm = filtfilt(b,a,prebutter);
                lightAmplitude = obj.stimMean + obj.stimStdDev .*(preNorm / std(preNorm));
            end
            
            % Create the stimulus
            stimulus = ones(1, (obj.rigConfig.sampleRate *(obj.preTime + obj.stimDur + obj.tailTime))) * obj.continuousLight;
            stimulus(obj.rigConfig.sampleRate * obj.preTime+1:obj.rigConfig.sampleRate *(obj.preTime+obj.stimDur))=lightAmplitude(101:end);
            obj.stimWave = stimulus;
        end
        
        
       function stimuli = sampleStimuli(obj)
           stimuli = cell(obj.numberOfAverages, 1);
          for i = 1:obj.numberOfAverages
              stimuli{i} = obj.stimulusForEpoch(i);
          end
       end
        
       function prepareEpoch(obj)
            % Call the base class method which sets up default backgrounds and records responses.
            prepareEpoch@SymphonyProtocol(obj);
            
            [stimulus, s] = obj.stimulusForEpoch(obj.epochNum); %call function generating light stim
            obj.addParameter('seed',s.Seed);
            obj.setDeviceBackground('LED', obj.continuousLight, 'V');
            if strcmp(obj.multiClampMode, 'VClamp')
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-3, 'V');
            else
                obj.setDeviceBackground('Amplifier_Ch1', double(obj.preSynapticHold) * 1e-12, 'A');
            end 
            obj.addStimulus('LED', 'LED stimulus', stimulus, 'V');    %
        end
        

        function completeEpoch(obj)
            
         %% Sam code for spikes detection (modified from Grid.protocol)   
             % Find spikes
            data=obj.response('Amplifier_Ch1');
            if obj.epochNum==1
                polarity = obj.spikePolThrLimRet(1);
                threshold = obj.spikePolThrLimRet(2);
                limitThresh = obj.spikePolThrLimRet(3);
                returnThresh = obj.spikePolThrLimRet(4);
            else
                polarity = str2double(get(obj.plotData.polarityEditHandle,'String'));
                threshold = str2double(get(obj.plotData.threshEditHandle,'String'));
                limitThresh = str2double(get(obj.plotData.limitEditHandle,'String'));
                returnThresh = str2double(get(obj.plotData.returnEditHandle,'String'));
            end
            % flip data and threshold if negative-going spike peaks
            if polarity<0
                data=-data; 
                threshold=-threshold;
                limitThresh=-limitThresh;
                returnThresh=-returnThresh;
            end
            % find sample number of spike peaks
            obj.plotData.spikePts=[];
            posThreshCross=find(data>=threshold,1);
            while ~isempty(posThreshCross)
                negThreshCross=posThreshCross+find(data(posThreshCross+1:end)<=returnThresh,1);
                if isempty(negThreshCross)
                    break;
                end
                [peak peakIndex]=max(data(posThreshCross:negThreshCross));
                if peak<limitThresh
                    obj.plotData.spikePts(end+1)=posThreshCross-1+peakIndex;
                end
                posThreshCross=negThreshCross+find(data(negThreshCross+1:end)>=threshold,1);
            end
            
            % Update mean responses (spike count)

                spikeTimes = obj.plotData.time(obj.plotData.spikePts);
                Resp = obj.plotData.spikePts(spikeTimes>(obj.preTime+obj.STAwindow) & spikeTimes<(obj.preTime+obj.stimDur));
                %Resp = find(obj.plotData.spikePts>((obj.preTime+obj.STAwindow)*obj.rigConfig.sampleRate) & obj.plotData.spikePts<((obj.preTime+obj.stimDur)*obj.rigConfig.sampleRate))
                singleSpikeTrigger = zeros(numel(Resp) , obj.rigConfig.sampleRate * obj.STAwindow);
                %timeWindow= zeros(1 , obj.rigConfig.sampleRate * obj.STAwindow);
               
                 for i = 1:numel(Resp)
                     timeWindow = Resp(i)-(obj.STAwindow*obj.rigConfig.sampleRate-1) : Resp(i);
                     singleSpikeTrigger(i,:) = obj.stimWave(timeWindow);
                 end              
                 trialSTA= mean(singleSpikeTrigger,1);
                 
                 if obj.epochNum==1
                     obj.plotData.meanSTA = trialSTA;
                     obj.plotData.numSpikes = numel(Resp);
                 else
                    obj.plotData.meanSTA = mean([repmat(obj.plotData.meanSTA,obj.plotData.numSpikes,1) ; repmat(trialSTA,numel(Resp),1)]);
                    obj.plotData.numSpikes = obj.plotData.numSpikes + numel(Resp);
                 end
     
            % Call the base class method which updates the figures.
            completeEpoch@SymphonyProtocol(obj);
            
            % Pause for the inter-pulse interval.
            pause on
            pause(obj.interpulseInterval);
        end
        
        function keepGoing = continueRun(obj)   
            % First check the base class method to make sure the user hasn't paused or stopped the protocol.
            keepGoing = continueRun@SymphonyProtocol(obj);
            
            if keepGoing
                keepGoing = obj.epochNum < obj.numberOfAverages;
            end
        end
    end
end