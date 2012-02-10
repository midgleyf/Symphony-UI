classdef Source < handle
    
    properties
        name
        identifier
        
        parentSource
        childSources
    end
    
    
    methods
        
        function obj = Source(name, varargin)
            if nargin == 2
                parent = varargin{1};
                
                % Check if the parent has a source with this name already.
                if isempty(parent)
                    existingSource = [];
                else
                    existingSource = parent.childWithName(name);
                end
                if isempty(existingSource)
                    % Keep this new source and link it to the parent.
                    obj.parentSource = parent;
                    obj.parentSource.childSources(end + 1) = obj;
                else
                    % Use the existing source instead.
                    obj = existingSource;
                    return;
                end
            else
                obj.parentSource = [];
            end
            
            obj.name = name;
            obj.identifier = System.Guid.NewGuid();
            
            obj.childSources = Source.empty(1, 0);
        end
        
        
        function path = path(obj)
            if isempty(obj.parentSource)
                path = obj.name;
            else
                path = [obj.parentSource.path() ':' obj.name];
            end
        end
        
        
        function a = ancestors(obj)
            if isempty(obj.parentSource)
                a = [];
            else
                parentAncestors = obj.parentSource.ancestors();
                a = [parentAncestors obj.parentSource];
            end
        end
        
        
        function c = childWithName(obj, name)
            c = [];
            for i = 1:length(obj.childSources)
                if strcmp(obj.childSources(i).name, name)
                    c = obj.childSources(i);
                    break;
                end
            end
        end
        
        
        function d = descendantAtPath(obj, path)
            if isempty(path)
                d = obj;
            else
                index = find(path == ':', 1, 'first');
                
                if isempty(index)
                    childName = path;
                    childPath = '';
                else
                    childName = path(1:index - 1);
                    childPath = path(index + 1:end);
                end
                d = obj.childWithName(childName);
                if ~isempty(d)
                    d = d.descendantAtPath(childPath);
                end
            end
        end
        
        
        function persistToMetadata(obj, parentNode)
            docNode = parentNode.getOwnerDocument();
            
            % Persist all ancestor sources.
            ancestors = obj.ancestors();
            for i = 2:length(ancestors)
                sourceNode = parentNode.appendChild(docNode.createElement('source'));
                sourceNode.setAttribute('label', ancestors(i).name);
                sourceNode.setAttribute('identifier', char(ancestors(i).identifier.ToString()));
                parentNode = sourceNode;
            end
            
            % Persist this source.
            sourceNode = parentNode.appendChild(docNode.createElement('source'));
            sourceNode.setAttribute('label', obj.name);
            sourceNode.setAttribute('identifier', char(obj.identifier.ToString()));
        end
        
        
        function syncWithMetadata(obj, sourceNode)
            % Update the UUID of this source.
            attr = sourceNode.getAttributes();
            obj.identifier = System.Guid(char(attr.getNamedItem('identifier').getNodeValue()));
            
            % Sync any child sources.
            children = sourceNode.getChildNodes();
            for i = 1:children.getLength()
                childNode = children.item(i-1);
                if childNode.getNodeType() == org.w3c.dom.Node.ELEMENT_NODE && ...
                   strcmp(char(childNode.getNodeName()), 'source')
                    attr = childNode.getAttributes();
                    childName = char(attr.getNamedItem('label').getNodeValue());
                    child = obj.childWithName(childName);
                    if isempty(child)
                        child = Source(label, obj);
                    end
                    child.syncWithMetadata(childNode);
                end
            end
        end
        
        
        function delete(obj)
            for i = 1:length(obj.childSources)
                delete(obj.childSources(i));
            end
        end
        
    end
    
end
