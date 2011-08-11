classdef Source < handle
    
    properties
        name
        parent
        children
    end
    
    methods
        
        function obj = Source(name, varargin)
            obj.name = name;
            if nargin == 2
                obj.parent = varargin{1};
                obj.parent.children(end + 1) = obj;
            else
                obj.parent = [];
            end
            obj.children = Source.empty(1, 0);
        end
        
        function path = path(obj)
            if isempty(obj.parent)
                path = obj.name;
            else
                path = [obj.parent.path() ':' obj.name];
            end
        end
        
        function a = ancestors(obj)
            if isempty(obj.parent)
                a = [];
            else
                parentAncestors = obj.parent.ancestors();
                a = [parentAncestors(:) obj.parent];
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
                d = [];
                for i = 1:length(obj.children)
                    if strcmp(obj.children(i).name, childName)
                        d = obj.children(i).descendantAtPath(childPath);
                        break;
                    end
                end
            end
        end
        
    end
    
end
