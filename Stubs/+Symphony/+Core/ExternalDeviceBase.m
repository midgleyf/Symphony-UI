classdef ExternalDeviceBase < Symphony.Core.IExternalDevice
   
    properties
    end
    
    methods
        function obj = ExternalDeviceBase(varargin)
            obj = obj@Symphony.Core.IExternalDevice(varargin{:});
        end
    end
end