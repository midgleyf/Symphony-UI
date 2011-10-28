classdef EPhys2PhotonStimGLRig < RigConfiguration
    
    properties (Constant)
        displayName = '2P Imaging, Spatial Stimuli, and Electrophysiology'
    end
    
    
    methods
        
        function createDevices(obj)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            obj.addDevice('LED', 'ANALOG_OUT.1', '');   % output only
            
            % Add the optical sensor. (input only)
            obj.addDevice('Photodiode', '', 'ANALOG_IN.1');
        end
        
    end
end
