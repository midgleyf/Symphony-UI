%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef MovingObjectsProtocol < StimGLProtocol

    properties (Constant)
        identifier = 'org.janelia.research.murphy.stimgl.movingobjects'
        version = 1
        displayName = 'Moving Objects Protocol'
        plugInName = 'MovingObjects'
    end

    properties
        objectShape = {'box', 'ellipse', 'sphere'}
        objectWidth = 10
        objectHeight = 10
        initialXPosition = 400
        initialYPosition = 400
        objectXVelocity = 10
        objectYVelocity = 10
        wrapAtEdges = true
        movementDuration = 1;
    end
    
    
    methods
        
        function set.objectShape(obj, shape)
            if ~any(strcmp(shape, {'box', 'ellipse', 'sphere'}))
                error 'The object shape must be "box", "ellipse" or "sphere".'
            end
            
            obj.objectShape = char(shape);
        end
        
        
        function s = epochDuration(obj)
            s = obj.movementDuration;
        end
        
        
        function params = pluginParameters(obj)
            % Get the default StimGL parameters.
            params = pluginParameters@StimGLProtocol(obj);
            
            % The moving objects plug-in calculates the total number of frames differently than other plug-ins.
            % It can loop through a list of speeds and sizes, running each for a number of frames.  In our case 
            % we handle looping outside of StimGL so we just need one loop.
            params.tFrames = params.nFrames;
            
            % Add the moving object parameters.
            params.objType = obj.objectShape;
            params.objLenX = obj.objectWidth;
            params.objLenY = obj.objectHeight;
            params.objXInit = obj.initialXPosition;
            params.objYInit = obj.initialYPosition;
            params.objVelX = obj.objectXVelocity;
            params.objVelY = obj.objectYVelocity;
            params.wrapEdge = uint8(obj.wrapAtEdges);
        end
        
    end
    
end