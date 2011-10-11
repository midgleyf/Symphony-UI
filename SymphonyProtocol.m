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
    
    
    properties (Hidden)
        state                       % The state the protocol is in: 'stopped', 'running', 'paused', etc.
        controller                  % A Symphony.Core.Controller instance.
        epoch = []                  % A Symphony.Core.Epoch instance.
        epochNum = 0                % The number of epochs that have been run.
        parametersEdited = false    % A flag indicating whether the user has edited the parameters.
        responses                   % A structure for caching converted responses.
        figureHandlerClasses
        figureHandlers = {}
        figureHandlerParams = {}
        allowSavingEpochs = true    % An indication if this protocol allows it's data to be persisted.
        persistor = []              % The persistor to use with each epoch.
        epochKeywords = {}          % A cell array of string containing keywords to be applied to any upcoming epochs.
    end
    
    
    events
        StateChanged
    end
    
    
    methods
        
        function obj = SymphonyProtocol()
            obj = obj@handle();
            
            obj.setState('stopped');
            obj.responses = containers.Map();
        end 
        
        
        function setState(obj, state)
            obj.state = state;
            notify(obj, 'StateChanged');
        end
        
        
        function prepareRun(obj)
            % Override this method to perform any actions before the start of the first epoch, e.g. open a figure window, etc.
            obj.epoch = [];
            obj.epochNum = 0;
            obj.clearFigures()
        end
        
        
        function pn = parameterNames(obj)
            % Return a cell array of strings containing the names of the user-defined parameters.
            % By default any parameters defined by a protocol that are not constant or hidden are included.
            
            names = properties(obj);
            pn = {};
            for nameIndex = 1:numel(names)
                name = names{nameIndex};
                metaProp = findprop(obj, name);
                if ~metaProp.Constant && ~metaProp.Hidden
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
        
        
        function prepareEpoch(obj)
            % Override this method to add stimulii, record responses, change parameters, etc.
            
            import Symphony.Core.*;
            
            % Create a new epoch.
            obj.epochNum = obj.epochNum + 1;
            obj.epoch = Epoch(obj.identifier);

            % Add any keywords specified by the user.
            for i = 1:length(obj.epochKeywords)
                obj.epoch.Keywords.Add(obj.epochKeywords{i});
            end
            
            % Set the default background value and record any input streams for each device.
            devices = listValues(obj.controller.Devices);
            for i = 1:length(devices)
                device = devices{i};
                
                % Set each device's background for this epoch to be the same as the inter-epoch background.
                obj.setDeviceBackground(device.Name, device.Background);
                
                % Record the response from any device that has an input stream.
                [~, streams] = dictionaryKeysAndValues(device.Streams);
                for j = 1:length(streams)
                    if isa(streams{j}, 'Symphony.Core.DAQInputStream')
                        obj.recordResponse(device.Name);
                        break
                    end
                end
            end
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
        
        
        function r = deviceSampleRate(obj, device, inOrOut)
            % Return the output sample rate for the given device based on any bound stream.
            
            import Symphony.Core.*;
            
            if ischar(device)
                deviceName = device;
                device = obj.controller.GetDevice(deviceName);
                
                if isempty(device)
                    error('There is no device named ''%s''.', deviceName);
                end
            end
            
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
        
        
        function addStimulus(obj, deviceName, stimulusID, stimulusData, units)
            % Queue data to send to the named device when the epoch is run.
            % TODO: need to specify data units?
            
            import Symphony.Core.*;
            
            device = obj.controller.GetDevice(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            if nargin == 4
                units = 'V';
                stimulusData = stimulusData .* 1e-3;
            end
            
            stimDataList = Measurement.FromArray(stimulusData, units);

            outputData = OutputData(stimDataList, obj.deviceSampleRate(device, 'OUT'), true);

            stim = RenderedStimulus(stimulusID, units, structToDictionary(struct()), outputData);

            obj.epoch.Stimuli.Add(device, stim);
            
            % Clear out the cache of responses now that we're starting a new epoch.
            % TODO: this would be cleaner to do in prepareEpoch() but that would require all protocols to call the super method...
            obj.responses = containers.Map();
        end
        
        
        function setDeviceBackground(obj, deviceName, background, units)
            % Set a constant stimulus value to be sent to the device.
            % TODO: totally untested
            
            import Symphony.Core.*;
            
            device = obj.controller.GetDevice(deviceName);
            if isempty(device)
                error('There is no device named ''%s''.', deviceName);
            end
            
            if nargin == 4
                background = Measurement(background, units);
            elseif isnumeric(background)
                background = Measurement(background, 'V');
            end
            obj.epoch.SetBackground(device, background, obj.deviceSampleRate(device, 'OUT'));
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
                
                s = System.Decimal.ToDouble(response.SampleRate.QuantityInBaseUnit);
                % TODO: do we care about the units of the SampleRate measurement?
                
                % Cache the results.
                obj.responses(deviceName) = struct('data', r, 'sampleRate', s, 'units', u);
            end
        end
        
        
        function completeEpoch(obj)
            % Override this method to perform any post-analysis, etc. on the current epoch.
            obj.updateFigures();
        end
        
        
        function keepGoing = continueRun(obj)
            % Override this method to return true/false based on the current state.
            % The object's epochNum is typically useful.
            
            keepGoing = strcmp(obj.state, 'running');
        end
        
        
        function completeRun(obj)
            % Override this method to perform any actions after the last epoch has completed.
            
            obj.setState('stopped');
        end
        
        
        function run(obj)
            % This is the core method that runs a protocol, everything else is preparation for this.
            
            try
                if ~strcmp(obj.state, 'paused')
                    % Prepare the run.
                    obj.prepareRun()
                end
                
                obj.setState('running');
                
                % Loop until the protocol or the user tells us to stop.
                while obj.continueRun()
                    % Run a single epoch.
                    
                    % Prepare the epoch: set backgrounds, add stimuli, record responses, add parameters, etc.
                    obj.prepareEpoch();
                    
                    % Persist the params now that the sub-class has had a chance to tweak them.
                    pluginParams = obj.parameters();
                    fields = fieldnames(pluginParams);
                    for fieldName = fields'
                        obj.epoch.ProtocolParameters.Add(fieldName{1}, pluginParams.(fieldName{1}));
                    end
                    
                    try
                        % Tell the Symphony framework to run the epoch.
                        obj.controller.RunEpoch(obj.epoch, obj.persistor);
                    catch e
                        % TODO: is it OK to hold up the run with the error dialog or should errors be logged and displayed at the end?
                        message = ['An error occurred while running the protocol.' char(10) char(10)];
                        if (isa(e, 'NET.NetException'))
                            message = [message netReport(e)]; %#ok<AGROW>
                        else
                            message = [message getReport(e, 'extended', 'hyperlinks', 'off')]; %#ok<AGROW>
                        end
                        waitfor(errordlg(message));
                    end
                    
                    % Perform any post-epoch analysis, clean up, etc.
                    obj.completeEpoch();
                    
                    % Force any figures to redraw and any events (clicking the Pause or Stop buttons in particular) to get processed.
                    drawnow;
                end
            catch e
                waitfor(errordlg(['An error occurred while running the protocol.' char(10) char(10) getReport(e, 'extended', 'hyperlinks', 'off')]));
            end
            
            if strcmp(obj.state, 'pausing')
                obj.setState('paused');
            else
                % Perform any final analysis, clean up, etc.
                obj.completeRun();
            end
        end
        
        
        function pause(obj)
            % Set a flag that will be checked after the current epoch completes.
            obj.setState('pausing');
        end
        
        
        function stop(obj)
            if strcmp(obj.state, 'paused')
                obj.completeRun()
            else
                % Set a flag that will be checked after the current epoch completes.
                obj.setState('stopping');
            end
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