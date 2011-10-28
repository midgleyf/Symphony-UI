classdef EPhysRig < RigConfiguration
    
    properties (Constant)
        displayName = 'Basic Electrophysiology'
    end
    
    
    methods
        
        function createDevices(obj)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            obj.addDevice('LED', 'ANALOG_OUT.1', '');   % output only
        end
        
    end
end
