classdef EPhys2PhotonRig < RigConfiguration
    
    properties (Constant)
        displayName = '2P Imaging & Electrophysiology'
    end
    
    
    methods
        
        function createDevices(obj)
            obj.addMultiClampDevice('Amplifier_Ch1', 1, 'ANALOG_OUT.0', 'ANALOG_IN.0');
            obj.addDevice('LED', 'ANALOG_OUT.1', '');   % output only
        end
        
    end
end
