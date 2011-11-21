classdef StimGLRig < RigConfiguration
    
    properties (Constant)
        displayName = 'In vivo Electrophysiology'
    end
    
    
    methods
        
        function createDevices(obj)
            % Create the same devices as an EPhysRig.
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            
            % Add the optical sensor. (input only)
            obj.addDevice('Photodiode', '', 'ANALOG_IN.1');
        end
        
    end
end

