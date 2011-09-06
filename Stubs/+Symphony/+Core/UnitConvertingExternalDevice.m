classdef UnitConvertingExternalDevice < Symphony.Core.ExternalDeviceBase
   
    properties
        MeasurementConversionTarget
    end
    
    methods
        function obj = UnitConvertingExternalDevice(varargin)
            obj = obj@Symphony.Core.ExternalDeviceBase(varargin{:});
        end
        
        function BindStream(obj, arg1, arg2)
            if nargin == 2
                obj.Streams.Add(arg1.Name, arg1);
            else
                obj.Streams.Add(arg1, arg2);
            end
        end
    end
end