classdef Ipulse < SymphonyProtocol
    
    properties (Constant)
        identifier = 'org.janelia.research.murphy.Ipulse'
        version = 1
        displayName = 'I pulse'
    end
    
    properties
        repeats = uint8(3);
        interEpochInt = 1.5;
        prePts = uint16(2000);
        stimPts = uint16(5000);
        postPts = uint16(3000);
        Iamp=[-800:200:-200,-150:50:-50,-25:25:25,50:50:150,200:200:1000];
    end
    
    properties (Dependent = true, SetAccess = private)
        sampleInterval;    % in microseconds, dependent until we can alter the device sample rate
    end
    
    methods
        
        function prepareRun(obj)
            obj.openFigure('Custom', 'Name', 'Responses', 'UpdateCallback', @updateResponsesFig);
        end
            
            
        function updateResponsesFig(obj, axesHandle)
            sampInt=1/10000*1000;
            t=sampInt:sampInt:sampInt*double(obj.prePts+obj.stimPts+obj.postPts);
            prevLineHandle=findobj(axesHandle,'type','line','color','k');
            set(prevLineHandle,'color',[0.8 0.8 0.8]);
            hold(axesHandle,'on');
            plot(axesHandle,t,obj.response,'k');
            xlabel(axesHandle,'ms');
            ylabel(axesHandle,'mV');
        end
        
        
        function prepareEpoch(obj)
            IampSequence=repmat(obj.Iamp,1,obj.repeats);
            epochIamp = IampSequence(obj.epochNum);
            stimulus = zeros(1,obj.prePts+obj.stimPts+obj.postPts);
            stimulus(obj.prePts+1:obj.prePts+obj.stimPts)=epochIamp;
            obj.addParameter('IAmp', epochIamp);
            obj.addStimulus('test-device', 'test-stimulus', stimulus);
            obj.setDeviceBackground('test-device', 0);
        end
        
        
        function completeEpoch(obj)
            pause on
            pause(obj.interEpochInt);
        end
        
        
        function keepGoing = continueRun(obj)
            keepGoing = obj.epochNum < numel(obj.Iamp)*double(obj.repeats);
        end
        
        
        function interval = get.sampleInterval(obj)
            interval = uint16(100);
        end
        
    end
end