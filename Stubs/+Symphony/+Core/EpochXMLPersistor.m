classdef EpochXMLPersistor < Symphony.Core.EpochPersistor
   
    properties
        path
        docNode
        groupNode
    end
    
    methods
        
        function obj = EpochXMLPersistor(xmlPath)
            obj = obj@Symphony.Core.EpochPersistor();
            
            obj.path = xmlPath;
            obj.docNode = com.mathworks.xml.XMLUtils.createDocument('epochGroup');
            obj.groupNode = obj.docNode.getDocumentElement;
        end
        
        
        function BeginEpochGroup(obj, label, parents, sources, keywords, properties, identifier)
            tz = java.util.TimeZone.getDefault();
            
            obj.groupNode.setAttribute('label', label);
            obj.groupNode.setAttribute('identifier', identifier);
            obj.groupNode.setAttribute('startTime', obj.formatDate(now));
            obj.groupNode.setAttribute('timeZone', tz.getDisplayName(tz.useDaylightTime, java.util.TimeZone.LONG));
            
            parentsNode = obj.groupNode.appendChild(obj.docNode.createElement('parents'));
            for i = 1:numel(parents)
                parentNode = parentsNode.appendChild(obj.docNode.createElement('parent'));
                parentNode.appendChild(obj.docNode.createTextNode(parents(i)));
            end
            
            sourcesNode = obj.groupNode.appendChild(obj.docNode.createElement('sourceHierarchy'));
            for i = 1:numel(sources)
                sourceNode = sourcesNode.appendChild(obj.docNode.createElement('source'));
                sourceNode.appendChild(obj.docNode.createTextNode(sources(i)));
            end
            
            keywordsNode = obj.groupNode.appendChild(obj.docNode.createElement('keywords'));
            for i = 1:numel(keywords)
                keywordNode = keywordsNode.appendChild(obj.docNode.createElement('keyword'));
                keywordNode.appendChild(obj.docNode.createTextNode(keywords(i)));
            end
            
            obj.serializeParameters(obj.groupNode, properties, 'properties');
        end
        
        
        function Serialize(obj, epoch)
            epochNode = obj.docNode.createElement('epoch');
            epochNode.setAttribute('protocolID', epoch.ProtocolID);
            epochNode.setAttribute('UUID', epoch.Identifier);
            epochNode.setAttribute('startTime', obj.formatDate(epoch.StartTime));
            obj.groupNode.appendChild(epochNode);
            
            % Serialize the device backgrounds.
            backgroundsNode = obj.docNode.createElement('background');
            epochNode.appendChild(backgroundsNode);
            for i = 1:epoch.Background.Count
                device = epoch.Background.Keys{i};
                background = epoch.Background.Values{i};
                backgroundNode = obj.docNode.createElement(device.Name);
                backgroundsNode.appendChild(backgroundNode);
                backgroundMeasurementNode = obj.docNode.createElement('backgroundMeasurement');
                backgroundNode.appendChild(backgroundMeasurementNode);
                obj.addMeasurementNode(backgroundMeasurementNode, background.Background, 'measurement');
                sampleRateNode = obj.docNode.createElement('sampleRate');
                backgroundNode.appendChild(sampleRateNode);
                obj.addMeasurementNode(sampleRateNode, background.SampleRate, 'measurement');
            end
            
            % Serialize the protocol parameters.
            obj.serializeParameters(epochNode, epoch.ProtocolParameters, 'protocolParameters');
            
            % Serialize the stimuli.
            stimuliNode = obj.docNode.createElement('stimuli');
            epochNode.appendChild(stimuliNode);
            for i = 1:epoch.Stimuli.Count
                device = epoch.Stimuli.Keys{i};
                stimulus = epoch.Stimuli.Values{i};
                stimulusNode = obj.docNode.createElement('stimulus');
                stimulusNode.setAttribute('device', device.Name); 
                stimulusNode.setAttribute('stimulusID', stimulus.StimulusID); 
                stimuliNode.appendChild(stimulusNode);
                
                obj.serializeParameters(stimulusNode, stimulus.Parameters, 'parameters');
            end
            
            % Serialize the responses.
            responsesNode = obj.docNode.createElement('responses');
            epochNode.appendChild(responsesNode);
            for i = 1:epoch.Responses.Count
                device = epoch.Responses.Keys{i};
                response = epoch.Responses.Values{i};
                responseNode = obj.docNode.createElement('response');
                responseNode.setAttribute('device', device.Name); 
                responsesNode.appendChild(responseNode);
                
                inputTimeNode = obj.docNode.createElement('inputTime');
                inputTimeNode.appendChild(obj.docNode.createTextNode(obj.formatDate(response.Data.InputTime)));
                responseNode.appendChild(inputTimeNode);
                sampleRateNode = obj.docNode.createElement('sampleRate');
                responseNode.appendChild(sampleRateNode);
                obj.addMeasurementNode(sampleRateNode, response.Data.SampleRate, 'measurement');
                dataNode = obj.docNode.createElement('data');
                responseNode.appendChild(dataNode);
                for i = 1:response.Data.Data.Count
                    obj.addMeasurementNode(dataNode, response.Data.Data.Item(i - 1), 'measurement');
                end
                obj.serializeParameters(responseNode, response.Data.ExternalDeviceConfiguration, 'externalDeviceConfiguration');
                obj.serializeParameters(responseNode, response.Data.StreamConfiguration, 'streamConfiguration');
            end
            
            % Serialize the keywords
            keywordsNode = obj.docNode.createElement('keywords');
            epochNode.appendChild(keywordsNode);
            for i = 1:epoch.Keywords.Count()
                keywordNode = keywordsNode.appendChild(obj.docNode.createElement('keyword'));
                keywordNode.appendChild(obj.docNode.createTextNode(epoch.Keywords.Item(i - 1)));
            end
        end
        
        
        function EndEpochGroup(obj) %#ok<MANU>
            
        end
        
        
        function Close(obj)
            xmlwrite(obj.path, obj.docNode);
        end
        
        
        function f = formatDate(obj, date) %#ok<MANU>
            tz = java.util.TimeZone.getDefault();
            tzOffset = tz.getOffset(now);
            if tz.useDaylightTime
                tzOffset = tzOffset + tz.getDSTSavings();
            end
            tzOffset = tzOffset / 1000 / 60;
            f = [datestr(date, 'mm/dd/yyyy HH:MM:SS PM') sprintf(' %+03d:%02d', tzOffset / 60, mod(tzOffset, 60))];
        end
        
        
        function serializeParameters(obj, rootNode, parameters, nodeName)
            paramsNode = obj.docNode.createElement(nodeName);
            rootNode.appendChild(paramsNode);
            for i = 1:parameters.Count
                name = parameters.Keys{i};
                value = parameters.Values{i};
                paramNode = obj.docNode.createElement(name);
                if islogical(value)
                    if value
                        paramNode.appendChild(obj.docNode.createTextNode('True'));
                    else
                        paramNode.appendChild(obj.docNode.createTextNode('False'));
                    end
                elseif isnumeric(value)
                    paramNode.appendChild(obj.docNode.createTextNode(num2str(value)));
                elseif ischar(value)
                    paramNode.appendChild(obj.docNode.createTextNode(value));
                else
                    error('Don''t know how to serialize parameters of type ''%s''', class(value));
                end
                paramsNode.appendChild(paramNode);
            end
        end
        
        
        function addMeasurementNode(obj, rootNode, measurement, nodeName)
            measurementNode = obj.docNode.createElement(nodeName);
            measurementNode.setAttribute('qty', num2str(measurement.Quantity));
            measurementNode.setAttribute('unit', measurement.Unit);
            rootNode.appendChild(measurementNode);
        end
    end
    
end