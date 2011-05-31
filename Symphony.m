function Symphony()
    % Add our utility folder to the search path.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    addpath(fullfile(parentDir, filesep, 'Utility'));
    
    if isempty(which('NET.convertArray'))
        addpath(fullfile(parentDir, filesep, 'Stubs'));
    else
        symphonyPath = 'C:\Program Files\Physion\Symphony';

        % Add Symphony.Core assemblies
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.Core.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.ExternalDevices.dll'));
        %NET.addAssembly(fullfile(symphonyPath, 'HekaDAQInterface.dll'));
        NET.addAssembly(fullfile(symphonyPath, 'Symphony.SimulationDAQController.dll'));
    end
    
    showMainWindow();
end


function controller = createSymphonyController(daqName, sampleRate)
    import Symphony.Core.*;
    import Symphony.SimulationDAQController.*;
    import Heka.*;
    
%    % Register Unit Converters
%    HekaDAQInputStream.RegisterConverters();
%    HekaDAQOutputStream.RegisterConverters();
    
    % Create Symphony.Core.Controller
    
    controller = Controller();
    
    if(strcmpi(daqName, 'heka'))
        daq = HekaDAQController(1, 0); %PCI18 = 1, USB18=5
        daq.SampleRate = sampleRate;
        
        % Finding input and output streams by name
        outStream = daq.GetStream('ANALOG_OUT.0');
        inStream = daq.GetStreams('ANALOG_IN.0');
    elseif(strcmpi(daqName, 'simulation'))
        if ~isempty(which('NET.convertArray'))
            Symphony.Core.Converters.Register('V','V', @(m) m);
        end
        daq = SimulationDAQController();
        
        outStream = DAQOutputStream('OUT');
        outStream.SampleRate = sampleRate;
        outStream.MeasurementConversionTarget = 'V';
        outStream.Clock = daq;
        daq.AddStream(outStream);
        
        inStream = DAQInputStream('IN');
        inStream.SampleRate = sampleRate;
        inStream.MeasurementConversionTarget = 'V';
        inStream.Clock = daq;
        daq.AddStream(inStream);
        
        daq.SimulationRunner = Simulation(@(output,step) loopbackSimulation(output, step, outStream, inStream));
       
    else
        error(['Unknown daqName: ' daqName]);
    end
        
    daq.Clock = daq;
    daq.Setup();
    
    controller.DAQController = daq;
    controller.Clock = daq;
    
    % Create external device and bind streams
    dev = ExternalDevice('test-device', controller, Measurement(0, 'V'));
    dev.Clock = daq;
    dev.MeasurementConversionTarget = 'V';
    dev.BindStream(outStream);
    dev.BindStream('input', inStream);
end


function input = loopbackSimulation(output, ~, outStream, inStream)
    import Symphony.Core.*;
    
    input = NET.createGeneric('System.Collections.Generic.Dictionary', {'Symphony.Core.IDAQInputStream','Symphony.Core.IInputData'});
    time = System.DateTimeOffset.Now;
    outData = output.Item(outStream);
    inData = InputData(outData.Data, outData.SampleRate, time, inStream.Configuration);
    input.Add(inStream, inData);
end


function showMainWindow()
    import Symphony.Core.*;
    
    if isempty(which('NET.convertArray'))
        sampleRate = Measurement(10000, 'Hz');
    else
        sampleRate = Symphony.Core.Measurement(10000, 'Hz');
    end
    handles.controller = createSymphonyController('simulation', sampleRate);
    
    % Get the list of protocols from the 'Protocols' folder.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    protocolsDir = fullfile(parentDir, filesep, 'Protocols');
    protocolDirs = dir(protocolsDir);
    handles.protocolClassNames = cell(length(protocolsDir), 1);
    protocolCount = 0;
    for i = 1:length(protocolDirs)
        if protocolDirs(i).isdir && ~strcmp(protocolDirs(i).name, '.') && ~strcmp(protocolDirs(i).name, '..') && ~strcmp(protocolDirs(i).name, '.svn')
            protocolCount = protocolCount + 1;
            handles.protocolClassNames{protocolCount} = protocolDirs(i).name;
            addpath(fullfile(protocolsDir, filesep, protocolDirs(i).name));
        end
    end
    handles.protocolClassNames = sort(handles.protocolClassNames(1:protocolCount));
    
    handles.figure = figure(...
        'Units', 'points', ...
        'Menubar', 'none', ...
        'Name', 'Symphony', ...
        'NumberTitle', 'off', ...
        'Position', centerWindowOnScreen(364, 280), ...
        'UserData', [], ...
        'Tag', 'figure');

    handles.startButton = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)startAcquisition(hObject,eventdata,guidata(hObject)), ...
        'Position', [7.2 252 56 20.8], ...
        'String', 'Start', ...
        'Tag', 'startButton');

    handles.stopButton = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)stopAcquisition(hObject,eventdata,guidata(hObject)), ...
        'Enable', 'off', ...
        'Position', [61.6 252 56 20.8], ...
        'String', 'Stop', ...
        'Tag', 'stopButton');
    
    % TODO: should param editor pop-up automatically the first time?
    handles.protocolPopup = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)chooseProtocol(hObject,eventdata,guidata(hObject)), ...
        'Position', [224.8 251.2 130.4 21.6], ...
        'String', {  'Pop-up Menu' }, ...
        'Style', 'popupmenu', ...
        'String', handles.protocolClassNames, ...
        'Value', 1, ...
        'Tag', 'protocolPopup');

    uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [168 255.2 56.8 17.6], ...
        'String', 'Protocol:', ...
        'Style', 'text', ...
        'Tag', 'text1');

    handles.saveEpochsCheckbox = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'Position', [7.2 222.4 100.8 18.4], ...
        'String', 'Save Epochs', ...
        'Style', 'checkbox', ...
        'Tag', 'saveEpochsCheckbox');

    uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [10.4 192.8 56.8 17.6], ...
        'String', 'Keywords:', ...
        'Style', 'text', ...
        'Tag', 'text2');

    handles.keywordsEdit = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [79 189 273 26], ...
        'String', blanks(0), ...
        'Style', 'edit', ...
        'Tag', 'keywordsEdit');

    handles.epochPanel = uipanel(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'Title', 'Epoch Group', ...
        'Tag', 'uipanel1', ...
        'Clipping', 'on', ...
        'Position', [13 70 336 111]);

    uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [8 74.4 67.2 17.6], ...
        'String', 'Output path:', ...
        'Style', 'text', ...
        'Tag', 'text3');

    handles.epochGroupOutputPathText = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [77.6 74.4 250.4 17.6], ...
        'String', getpref('Symphony', 'EpochGroupOutputPath', ''), ...
        'Style', 'text', ...
        'Tag', 'epochGroupOutputPathText');

    uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [8 58.4 67.2 17.6], ...
        'String', 'Label:', ...
        'Style', 'text', ...
        'Tag', 'text5');

    handles.epochGroupLabelText = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [77.6 58.4 250.4 17.6], ...
        'String', getpref('Symphony', 'EpochGroupLabel', ''), ...
        'Style', 'text', ...
        'Tag', 'epochGroupLabelText');

    uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [8 42.4 67.2 17.6], ...
        'String', 'Source:', ...
        'Style', 'text', ...
        'Tag', 'text7');

    handles.epochGroupSourceText = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [77.6 42.4 250.4 17.6], ...
        'String', getpref('Symphony', 'EpochGroupSource', ''), ...
        'Style', 'text', ...
        'Tag', 'epochGroupSourceText');

    handles.newEpochGroupButton = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)createNewEpochGroup(hObject,eventdata,guidata(hObject)), ...
        'Position', [224.8 9.6 97.6 20.8], ...
        'String', 'New Epoch Group', ...
        'Tag', 'newEpochGroupButton');

    handles.experimentPanel = uipanel(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'Title', 'Experiment', ...
        'Tag', 'experimentPanel', ...
        'Clipping', 'on', ...
        'Position', [14.4 16.8 333.6 41.6]);

    uicontrol(...
        'Parent', handles.experimentPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [6.4 7.2 67.2 17.6], ...
        'String', 'Mouse ID:', ...
        'Style', 'text', ...
        'Tag', 'text9');

    handles.mouseIDText = uicontrol(...
        'Parent', handles.experimentPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [76 7.2 250.4 17.6], ...
        'String', blanks(0), ...
        'Style', 'text', ...
        'Tag', 'mouseIDText');

    guidata(handles.figure, handles);
end


function chosen = chooseProtocol(~, ~, handles)
    pluginIndex = get(handles.protocolPopup, 'Value');
    pluginClassName = handles.protocolClassNames{pluginIndex};
    
    if ~isfield(handles, 'protocolPlugin') || ~isa(handles.protocolPlugin, pluginClassName)
        handles.protocolPlugin = eval([pluginClassName '(handles.controller)']);
        
        % Use any previously set parameters.
        params = getpref('ProtocolDefaults', class(handles.protocolPlugin), struct);
        paramNames = fieldnames(params);
        for i = 1:numel(paramNames)
            handles.protocolPlugin.(paramNames{i}) = params.(paramNames{i});
        end

        chosen = editParameters(handles.protocolPlugin);
        
        guidata(handles.figure, handles);
    else
        % The protocol has already been chosen.
        chosen = true;
    end
end


function createNewEpochGroup(~, ~, handles)
    [outputPath, label, source] = newEpochGroup();
    if ~isempty(outputPath)
        set(handles.epochGroupOutputPathText, 'String', outputPath);
        set(handles.epochGroupLabelText, 'String', label);
        set(handles.epochGroupSourceText, 'String', source);
        setpref('Symphony', 'EpochGroupOutputPath', outputPath)
        setpref('Symphony', 'EpochGroupLabel', label)
        setpref('Symphony', 'EpochGroupSource', source)
    end
end


function startAcquisition(~, ~, handles)
    if chooseProtocol([], [], handles)
        handles = guidata(handles.figure);
    else
        return
    end
    
    % Disable/enable the appropriate GUI
    set([handles.startButton, handles.protocolPopup, handles.saveEpochsCheckbox, handles.newEpochGroupButton], 'Enable', 'off');
    set(handles.stopButton, 'Enable', 'on');
    
    % Wrap the rest in a try/catch block so we can be sure to reenable the GUI.
    try
        import Symphony.Core.*;
    
        xmlRootPath = get(handles.epochGroupOutputPathText, 'String');
        xmlPath = fullfile(xmlRootPath, [class(handles.protocolPlugin) '_' datestr(now, 30) '.xml']);
        persistor = EpochXMLPersistor(xmlPath);

        parentArray = NET.createArray('System.String', 0);
        % TODO: populate parents (from where?)

        hierarchy = sourceHierarchy(get(handles.epochGroupSourceText, 'String'));
        sourceArray = NET.createArray('System.String', numel(hierarchy));
        for i = 1:numel(hierarchy)
            sourceArray(i) = hierarchy{i};
        end

        keywordsText = get(handles.keywordsEdit, 'String');
        keywords = strtrim(regexp(keywordsText, ',', 'split'));
        if isequal(keywords, {''})
            keywords = {};
        end
        keywordArray = NET.createArray('System.String', numel(keywords));
        for i = 1:numel(keywords)
            keywordArray(i) = keywords{i};
        end

        label = get(handles.epochGroupLabelText, 'String');

        runProtocol(handles.protocolPlugin, persistor, label, parentArray, sourceArray, keywordArray, System.Guid.NewGuid());
    catch ME
        % Reenable the GUI.
        set([handles.startButton, handles.protocolPopup, handles.saveEpochsCheckbox, handles.newEpochGroupButton], 'Enable', 'off');
        set(handles.stopButton, 'Enable', 'on');
        
        rethrow(ME);
    end
    
    % Reenable the GUI.
    set([handles.startButton, handles.protocolPopup, handles.saveEpochsCheckbox, handles.newEpochGroupButton], 'Enable', 'off');
    set(handles.stopButton, 'Enable', 'on');
end


function h = sourceHierarchy(source)
    h = {};
    
    while ~isempty(source)
        h{end + 1} = source; %#ok<AGROW>
        source = sourceParent(source);
    end
end


function p = sourceParent(source)
    if ispref('Symphony', 'Sources')
        sources = getpref('Symphony', 'Sources');
        index = find(strcmp({sources.label}, source));
        p = sources(index).parent; %#ok<FNDSB>
    else
        p = '';
    end
end


function runProtocol(protocolPlugin, persistor, label, parents, sources, keywords, identifier)
    import Symphony.Core.*;
    
    % Open a figure window to show the response of each epoch.
    figure('Name', [class(protocolPlugin) ': Response'], ...
           'NumberTitle', 'off');
    responseAxes = axes('Position', [0.1 0.1 0.85 0.85]);
    responsePlot = plot(responseAxes, 1:100, zeros(1, 100));
    xlabel(responseAxes, 'sec');
    drawnow expose;
    
    % Set up the persistor.
    persistor.BeginEpochGroup(label, parents, sources, keywords, identifier);
    
    try
        % Initialize the run.
        protocolPlugin.epoch = [];
        protocolPlugin.epochNum = 0;
        protocolPlugin.prepareEpochGroup()

        % Loop through all of the epochs.
        while protocolPlugin.continueEpochGroup()
            % Create a new epoch.
            protocolPlugin.epochNum = protocolPlugin.epochNum + 1;
            protocolPlugin.epoch = Epoch(protocolPlugin.identifier);

            % Let sub-classes add stimulii, record responses, tweak params, etc.
            protocolPlugin.prepareEpoch();

            % Set the params now that the sub-class has had a chance to tweak them.
            protocolPlugin.epoch.ProtocolParameters = structToDictionary(protocolPlugin.parameters());

            % Run the epoch.
            try
                protocolPlugin.controller.RunEpoch(protocolPlugin.epoch, persistor);
                
                persistor.Serialize(protocolPlugin.epoch);
                
                % Plot the response.
                 [responseData, sampleRate, units] = protocolPlugin.response();
                 duration = numel(responseData) / sampleRate;
                 samplesPerTenth = sampleRate / 10;
                 set(responsePlot, 'XData', 1:numel(responseData), ...
                                   'YData', responseData);
                 set(responseAxes, 'XTick', 1:samplesPerTenth:numel(responseData), ...
                                   'XTickLabel', 0:.1:duration);
                 ylabel(responseAxes, units);
                 drawnow expose;
            catch e
                % TODO: is it OK to hold up the run with the error dialog or should errors be displayed at the end?
                if (isa(e, 'NET.NetException'))
                    eObj = e.ExceptionObject;
                    ed = errordlg(char(eObj.Message));
                else
                    ed = errordlg(e.message);
                end
                waitfor(ed);
            end
            
            % Let the sub-class perform any post-epoch analysis, clean up, etc.
            protocolPlugin.completeEpoch();
        end
    catch e
        ed = errordlg(e.message);
        waitfor(ed);
    end
    
    % Let the sub-class perform any final analysis, clean up, etc.
    protocolPlugin.completeEpochGroup();
    
    persistor.EndEpochGroup();
    persistor.Close();
end
