%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html
%
% Modified 27-Aug-2012 TWA to create new Color Rig

classdef PALPatchRig < RigConfiguration
    
    properties (Constant)
        displayName = 'Retina Electrophysiology'
    end
    
    
    methods
        
        function createDevices(obj)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            obj.addDevice('Red_LED', 'ANALOG_OUT.1', '');   % output only
            obj.addDevice('Green_LED', 'ANALOG_OUT.2', '');   % output only
            obj.addDevice('Blue_LED', 'ANALOG_OUT.3', '');   % output only
        end
        
    end
end