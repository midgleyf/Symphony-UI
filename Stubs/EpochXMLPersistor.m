classdef EpochXMLPersistor < EpochPersistor
   
    properties
        path
        docNode
        groupNode
    end
    
    methods
        function obj = EpochXMLPersistor(xmlPath)
            obj = obj@EpochPersistor();
            
            obj.path = xmlPath;
            obj.docNode = com.mathworks.xml.XMLUtils.createDocument('epochGroup');
            obj.groupNode = obj.docNode.getDocumentElement;
        end
        
        function BeginEpochGroup(obj, label, parents, sources, keywords, identifier)
            obj.groupNode.setAttribute('label', label);
            obj.groupNode.setAttribute('identifier', identifier);
            obj.groupNode.setAttribute('startTime', datestr(now, 'mm/dd/yyyy HH:MM:SS PM'));
            % TODO: figure out how to get the current time zone.  Java?
%            obj.groupNode.setAttribute('timeZone', label);
            
            parentsNode = obj.groupNode.appendChild(obj.docNode.createElement('parents'));
            for i = 1:parents.Count
                parentsNode.appendChild(obj.docNode.createTextNode(parents{i}));
            end
            
            sourcesNode = obj.groupNode.appendChild(obj.docNode.createElement('sources'));
            for source = 1:sources.Count
                sourcesNode.appendChild(obj.docNode.createTextNode(sources{i}));
            end
            
            keywordsNode = obj.groupNode.appendChild(obj.docNode.createElement('keywords'));
            for keyword = 1:keywords.Count
                keywordsNode.appendChild(obj.docNode.createTextNode(keywords{i}));
            end
        end
        
        function SerializeEpoch(obj, epoch)
            epochNode = obj.docNode.createElement('epoch');
            epochNode.setAttribute('protocolID', epoch.ProtocolID);
            % TODO: add UUID attribute
            obj.groupNode.appendChild(epochNode);
            
            % Serialize the background node.
            % TODO: add attributes/child elements
            epochNode.appendChild(obj.docNode.createElement('background'));
            
            % Serialize the protocol parameters.
            % TODO: add the parameters
            epochNode.appendChild(obj.docNode.createElement('protocolParameters'));
            
            % Serialize the stimuli.
            stimuliNode = obj.docNode.createElement('stimuli');
            epochNode.appendChild(stimuliNode);
            for i = 1:numel(epoch.Stimuli.Keys)
                device = epoch.Stimuli.Keys{i};
                stimulus = epoch.Stimuli.Values{i};
                stimulusNode = obj.docNode.createElement('stimulus');
                stimulusNode.setAttribute('device', device.Name); 
                stimulusNode.setAttribute('stimulusNode', stimulus.StimulusID); 
                stimuliNode.appendChild(stimulusNode);
                
                % TODO: add parameters
                stimulusNode.appendChild(obj.docNode.createElement('parameters'));
            end
            
            % Serialize the responses.
            responsesNode = obj.docNode.createElement('responses');
            epochNode.appendChild(responsesNode);
            for i = 1:numel(epoch.Responses.Keys)
                device = epoch.Responses.Keys{i};
                responseNode = obj.docNode.createElement('response');
                responseNode.setAttribute('device', device.Name); 
                responsesNode.appendChild(responseNode);
            end
        end
        
        function EndEpochGroup(obj) %#ok<MANU>
            
        end
        
        function Close(obj)
            xmlwrite(obj.path, obj.docNode);
        end
    end
    
end