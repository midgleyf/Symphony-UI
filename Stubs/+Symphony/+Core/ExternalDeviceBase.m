%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef ExternalDeviceBase < Symphony.Core.IExternalDevice
   
    properties
    end
    
    methods
        function obj = ExternalDeviceBase(varargin)
            obj = obj@Symphony.Core.IExternalDevice(varargin{:});
        end
    end
end