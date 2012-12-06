%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef ExampleRig < RigConfiguration
    
    properties (Constant)
        displayName = 'Example Rig'
    end
    
    methods
        
        function obj = ExampleRig(allowMultiClampDevices)
            args = {};
            if nargin > 0
                args{1} = allowMultiClampDevices;
            end
            obj = obj@RigConfiguration(args{:});
        end
        
        
        function createDevices(obj)     
            % Add a multiclamp device named 'Amplifier_Ch1'.
            % Multiclamp Channel = 1
            % ITC Output Channel = DAC Output 0 (ANALOG_OUT.0)
            % ITC Input Channel = ADC Input 0 (ANALOG_IN.0)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0'); 
            
            % Add a device named 'LED'.
            % ITC Output Channel = DAC Output 1 (ANALOG_OUT.1)
            % ITC Input Channel = None
            obj.addDevice('LED', 'ANALOG_OUT.1', '');
            
            % Add a device named 'Photodiode'.
            % ITC Output Channel = None
            % ITC Input Channel = ADC Input 0 (ANALOG_IN.1)
            obj.addDevice('Photodiode', '', 'ANALOG_IN.1');
            
            % Add a device named 'Oscilliscope_Trig'.
            % ITC Output Channel = TTL Output 0 (DIGITAL_OUT.0)
            % ITC Input Channel = None
            obj.addDevice('Oscilliscope_Trig', 'DIGITAL_OUT.0', '');
        end
        
    end
end
