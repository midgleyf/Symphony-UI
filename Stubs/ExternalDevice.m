classdef ExternalDevice < handle
   
    properties
        Name
        Controller
        Background
        MeasurementConversionTarget
    end
    
    methods
        function obj = ExternalDevice(name, controller, background)
            obj = obj@handle();
            
            obj.Name = name;
            obj.Controller = controller;
            obj.Background = background;
            
            obj.Controller.Devices{end + 1} = obj;
        end
        
        function BindStream(obj, stream) %#ok<MANU,INUSD>
        end
    end
end