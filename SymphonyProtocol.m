classdef SymphonyProtocol < handle & matlab.mixin.Copyable
    % Create a sub-class of this class to define a protocol.
    %
    % Interesting methods to override:
    % * prepareRun
    % * prepareEpoch
    % * completeEpoch
    % * continueRun
    % * completeRun
    %
    % Useful methods:
    % * addStimulus
    % * setDeviceBackground
    % * recordResponse
    
    properties (Constant, Abstract)
        identifier
        version
        displayName
    end
    
    
    properties
        controller                  % A Symphony.Core.Controller instance.
        epoch = []                  % A Symphony.Core.Epoch instance.
        epochNum = 0                % The number of epochs that have been run.
        parametersEdited = false    % A flag indicating whether the user has edited the parameters.
        responses                   % A structure for caching converted responses.
        figureHandlerClasses
        figureHandlers = {}
        figureHandlerParams = {}
    end
    
    
    methods
        
        function obj = SymphonyProtocol()
            obj = obj@handle();
            
            obj.responses = containers.Map();
        end 
        
        
        function prepareRun(obj) %#ok<MANU>
            % Override this method to perform any actions before the start of the first epoch, e.g. open a figure window, etc.
        end
        
        
        function pn = parameterNames(obj)
            % Return a cell array of strings containing the names of the user-defined parameters.
            % By default any parameters defined by a protocol are included.
            
            % TODO: exclude parameters that start with an underscore?
            
            excludeNames = {'identifier', 'version', 'displayName', 'controller', 'epoch', 'epochNum', 'parametersEdited', 'responses', 'figureHandlerClasses', 'figureHandlers', 'figureHandlerParams'};
            names = properties(obj);
            pn = {};
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                if ~any(strcmp(name, excludeNames))
                    pn{end + 1} = name; %#ok<AGROW>
                end
            end
            pn = pn';
        end
        
        
        function p = parameters(obj)
            % Return a struct containing the user-defined parameters.
            % By default any parameters defined by a protocol are included.
            
            names = obj.parameterNames();
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                p.(name) = obj.(name);
            end
        end
        
        
        function [stimuli, sampleRate] = sampleStimuli(~)
            stimuli = {};
            sampleRate = 10000;
        end
        
        
        function prepareEpoch(obj) %#ok<MANU>
            % Override this method to add stimulii, record responses, change parameters, etc.
            
            % TODO: record responses for all inputs by default?
        end
        
        
        function addParameter(obj, name, value)
            obj.epoch.ProtocolParameters.Add(name, value);
        end
        
        
        function p = epochSpecificParameters(obj)
            % Determine the parameters unique to the current epoch.
            % TODO: diff against the previous epoch's parameters instead?
            protocolParams = obj.parameters();
            p = structDiff(dictionaryToStruct(obj.epoch.ProtocolParameters), protocolParams);
        end
        
        
        function r = deviceSampleRate(obj, device, inOrOut) %#ok<MANU>
            % Return the output sample rate for the given device based on any bound stream.
            
            import Symphony.Core.*;
            
            r = Measurement(10000, 'Hz');   % default if no output stream is found
            [~, streams] = dictionaryKeysAndValues(device.Streams);
            for index = 1:numel(streams)
                stream = streams{index};
                if (strcmp(inOrOut, 'IN') && isa(stream, 'DAQInputStream')) || (strcmp(inOrOut, 'OUT') && isa(stream, 'DAQOutputStream'))
                    r = stream.SampleRate;
                    break;
                end
            end
        end
        
        
        function addStimulus(obj, deviceName, stimulusID, stimulusData)
            % Queue data to send to the named device when the epoch is run.
            % TODO: need to specify data units?
            
            import Symphony.Core.*;
            
            device = obj.controller.GetDevice(deviceName);
            % TODO: what happens when there is no device with that name?
            
            stimDataList = Measurement.FromArray(stimulusData.*1e-3, 'V');

            outputData = OutputData(stimDataList, obj.deviceSampleRate(device, 'OUT'), true);

            stim = RenderedStimulus(stimulusID, structToDictionary(struct()), outputData);

            obj.epoch.Stimuli.Add(device, stim);
            
            % Clear out the cache of responses now that we're starting a new epoch.
            % TODO: this would be cleaner to do in prepareEpoch() but that would require all protocols to call the super method...
            obj.responses = containers.Map();
        end
        
        
        function setDeviceBackground(obj, deviceName, volts)
            % Set a constant stimulus value to be sent to the device.
            % TODO: totally untested
            
            import Symphony.Core.*;
            
            device = obj.controller.GetDevice(deviceName);
            % TODO: what happens when there is no device with that name?
            
            obj.epoch.SetBackground(device, Measurement(volts, 'V'), obj.deviceSampleRate(device, 'OUT'));
        end
        
        
        function recordResponse(obj, deviceName)
            % Record the response from the device with the given name when the epoch runs.
            
            import Symphony.Core.*;
            
            device = obj.controller.GetDevice(deviceName);
            % TODO: what happens when there is no device with that name?
            
            obj.epoch.Responses.Add(device, Response());
        end
        
        
        function [r, s, u] = response(obj, deviceName)
            % Return the response, sample rate and units recorded from the device with the given name.
            
            import Symphony.Core.*;
            
            if nargin == 1
                % If no device specified then pick the first one.
                devices = dictionaryKeysAndValues(obj.epoch.Responses);
                if isempty(devices)
                    error('Symphony:NoDevicesRecorded', 'No devices have had their responses recorded.');
                end
                device = devices{1};
            else
                device = obj.controller.GetDevice(deviceName);
                % TODO: what happens when there is no device with that name?
            end
            
            deviceName = char(device.Name);
            
            if isKey(obj.responses, deviceName)
                % Use the cached response data.
                response = obj.responses(deviceName);
                r = response.data;
                s = response.sampleRate;
                u = response.units;
            else
                % Extract the raw data.
                response = obj.epoch.Responses.Item(device);
                data = response.Data;
                r = double(Measurement.ToQuantityArray(data));
                u = char(Measurement.HomogenousUnits(data));
                
                s = response.SampleRate.QuantityInBaseUnit;
                % TODO: do we care about the units of the SampleRate measurement?
                
                % Cache the results.
                obj.responses(deviceName) = struct('data', r, 'sampleRate', s, 'units', u);
            end
        end
        
        
        function completeEpoch(obj) %#ok<MANU>
            % Override this method to perform any post-analysis, etc. on the current epoch.
        end
        
        
        function keepGoing = continueRun(obj) %#ok<MANU>
            % Override this method to return true/false based on the current state.
            % The object's epochNum is typically useful.
            
            keepGoing = false;
        end
        
        
        function completeRun(obj) %#ok<MANU>
            % Override this method to perform any actions after the last epoch has completed.
        end
    end
    
    
    methods
        
        % Figure handling methods.
        
        function handler = openFigure(obj, figureType, varargin)
            if ~isKey(obj.figureHandlerClasses, figureType)
                error('The ''%s'' figure handler is not available.', figureType);
            end
            
            handlerClass = obj.figureHandlerClasses(figureType);
            
            % Check if the figure is open already.
            for i = 1:length(obj.figureHandlers)
                if strcmp(class(obj.figureHandlers{i}), handlerClass) && isequal(obj.figureHandlerParams{i}, varargin)
                    handler = obj.figureHandlers{i};
                    handler.showFigure();
                    return
                end
            end
            
            % Create a new handler.
            constructor = str2func(handlerClass);
            handler = constructor(obj, varargin{:});
            addlistener(handler, 'FigureClosed', @(source, event)figureClosed(obj, source, event));
            obj.figureHandlers{end + 1} = handler;
            obj.figureHandlerParams{end + 1} = varargin;
        end
        
        
        function updateFigures(obj)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.handleCurrentEpoch();
            end
        end
        
        
        function clearFigures(obj)
            for index = 1:numel(obj.figureHandlers)
                figureHandler = obj.figureHandlers{index};
                figureHandler.clearFigure();
            end
        end
        
        
        function closeFigures(obj)
            % Close any figures that were opened.
            while ~isempty(obj.figureHandlers)
                obj.figureHandlers{1}.close();
            end
        end
        
        
        function figureClosed(obj, handler, ~)
            % Remove the handler from our list.
            index = cellfun(@(x) x == handler, obj.figureHandlers);
            obj.figureHandlers(index) = [];
            obj.figureHandlerParams(index) = [];
        end
        
    end
    
end