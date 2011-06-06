function Symphony()
    % Add our utility folder to the search path.
    symphonyPath = mfilename('fullpath');
    parentDir = fileparts(symphonyPath);
    addpath(fullfile(parentDir, filesep, 'Utility'));
    addpath(fullfile(parentDir, filesep, 'Figure Handlers'));
    
    addSymphonyFramework();
    
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
        daq.InitHardware();
        daq.SampleRate = sampleRate;
        
        % Finding input and output streams by name
        outStream = daq.GetStream('ANALOG_OUT.0');
        inStream = daq.GetStream('ANALOG_IN.0');
    elseif(strcmpi(daqName, 'simulation'))
        if ~isempty(which('NET.convertArray'))
            Symphony.Core.Converters.Register('V','V', @(m) m);
        end
        daq = SimulationDAQController();
        daq.Setup();
        
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
    
    controller.DAQController = daq;
    controller.Clock = daq;
    
    % Create external device and bind streams
    dev = ExternalDevice('test-device', controller, Measurement(0, 'V'));
    dev.Clock = daq;
    dev.MeasurementConversionTarget = 'V';
    dev.BindStream(outStream);
    dev.BindStream(inStream);
end


function input = loopbackSimulation(output, ~, outStream, inStream)
    import Symphony.Core.*;
    
    input = NET.createGeneric('System.Collections.Generic.Dictionary', {'Symphony.Core.IDAQInputStream','Symphony.Core.IInputData'});
    time = System.DateTimeOffset.Now;
    outData = output.Item(outStream);
    inData = InputData(outData.Data, outData.SampleRate, time, inStream.Configuration);
    input.Add(inStream, inData);
end


%% GUI layout/control


function showMainWindow()
    import Symphony.Core.*;
    
    sampleRate = Measurement(10000, 'Hz');
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
    lastChosenProtocol = getpref('Symphony', 'LastChosenProtocol', handles.protocolClassNames{1});
    protocolValue = find(strcmp(handles.protocolClassNames, lastChosenProtocol));
    
    handles.figure = figure(...
        'Units', 'points', ...
        'Menubar', 'none', ...
        'Name', 'Symphony', ...
        'NumberTitle', 'off', ...
        'ResizeFcn', @(hObject,eventdata)windowDidResize(hObject,eventdata,guidata(hObject)), ...
        'Position', centerWindowOnScreen(364, 280), ...
        'UserData', [], ...
        'Tag', 'figure');
    
    bgColor = get(handles.figure, 'Color');
    
    handles.startButton = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)startAcquisition(hObject,eventdata,guidata(hObject)), ...
        'Position', [7.2 252 56 20.8], ...
        'BackgroundColor', bgColor, ...
        'String', 'Start', ...
        'Tag', 'startButton');

    handles.stopButton = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)stopAcquisition(hObject,eventdata,guidata(hObject)), ...
        'Enable', 'off', ...
        'Position', [61.6 252 56 20.8], ...
        'BackgroundColor', bgColor, ...
        'String', 'Stop', ...
        'Tag', 'stopButton');
    
    % TODO: should param editor pop-up automatically the first time?
    handles.protocolPopup = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)chooseProtocol(hObject,eventdata,guidata(hObject)), ...
        'Position', [224.8 251.2 130.4 21.6], ...
        'BackgroundColor', bgColor, ...
        'String', {  'Pop-up Menu' }, ...
        'Style', 'popupmenu', ...
        'String', handles.protocolClassNames, ...
        'Value', protocolValue, ...
        'Tag', 'protocolPopup');

    handles.protocolLabel = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [168 255.2 56.8 17.6], ...
        'BackgroundColor', bgColor, ...
        'String', 'Protocol:', ...
        'Style', 'text', ...
        'Tag', 'text1');

    handles.saveEpochsCheckbox = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'Position', [7.2 222.4 100.8 18.4], ...
        'BackgroundColor', bgColor, ...
        'Enable', 'off', ...
        'String', 'Save Epochs', ...
        'Value', 1, ...
        'Style', 'checkbox', ...
        'Tag', 'saveEpochsCheckbox');

    handles.keywordsLabel = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [10.4 192.8 56.8 17.6], ...
        'BackgroundColor', bgColor, ...
        'String', 'Keywords:', ...
        'Style', 'text', ...
        'Tag', 'text2');

    handles.keywordsEdit = uicontrol(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [79 189 273 26], ...
        'BackgroundColor', bgColor, ...
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
        'Position', [13 70 336 111], ...
        'BackgroundColor', bgColor);

    uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [8 74 67 16], ...
        'BackgroundColor', bgColor, ...
        'String', 'Output path:', ...
        'Style', 'text', ...
        'Tag', 'text3');

    handles.epochGroupOutputPathText = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [78 75 250 14], ...
        'BackgroundColor', bgColor, ...
        'String', getpref('Symphony', 'EpochGroupOutputPath', ''), ...
        'Style', 'text', ...
        'Tag', 'epochGroupOutputPathText');

    uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [8 58 67 16], ...
        'BackgroundColor', bgColor, ...
        'String', 'Label:', ...
        'Style', 'text', ...
        'Tag', 'text5');

    handles.epochGroupLabelText = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [78 59 250 14], ...
        'BackgroundColor', bgColor, ...
        'String', getpref('Symphony', 'EpochGroupLabel', ''), ...
        'Style', 'text', ...
        'Tag', 'epochGroupLabelText');

    uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [8 42 67 16], ...
        'BackgroundColor', bgColor, ...
        'String', 'Source:', ...
        'Style', 'text', ...
        'Tag', 'text7');

    handles.epochGroupSourceText = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [78 43 250 14], ...
        'BackgroundColor', bgColor, ...
        'String', getpref('Symphony', 'EpochGroupSource', ''), ...
        'Style', 'text', ...
        'Tag', 'epochGroupSourceText');

    handles.newEpochGroupButton = uicontrol(...
        'Parent', handles.epochPanel, ...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)createNewEpochGroup(hObject,eventdata,guidata(hObject)), ...
        'Position', [224.8 9.6 97.6 20.8], ...
        'BackgroundColor', bgColor, ...
        'String', 'New Epoch Group', ...
        'Tag', 'newEpochGroupButton');

    handles.experimentPanel = uipanel(...
        'Parent', handles.figure, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'Title', 'Experiment', ...
        'Tag', 'experimentPanel', ...
        'Clipping', 'on', ...
        'Position', [14.4 16.8 333.6 41.6], ...
        'BackgroundColor', bgColor);

    uicontrol(...
        'Parent', handles.experimentPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'right', ...
        'Position', [6.4 7.2 67.2 17.6], ...
        'BackgroundColor', bgColor, ...
        'String', 'Mouse ID:', ...
        'Style', 'text', ...
        'Tag', 'text9');

    handles.mouseIDText = uicontrol(...
        'Parent', handles.experimentPanel, ...
        'Units', 'points', ...
        'FontSize', 12, ...
        'HorizontalAlignment', 'left', ...
        'Position', [76 7.2 250.4 17.6], ...
        'BackgroundColor', bgColor, ...
        'String', blanks(0), ...
        'Style', 'text', ...
        'Tag', 'mouseIDText');
    
    guidata(handles.figure, handles);
    
    drawnow
    
    % Attempt to set the minimum window size using Java.
    try
        set(handles.figure, 'Units', 'pixels');
        figPos = get(handles.figure, 'OuterPosition');
        set(handles.figure, 'Units', 'points');
        
        jFigPeer = get(handle(handles.figure),'JavaFrame');
        jWindow = jFigPeer.fFigureClient.getWindow;
        if ~isempty(jWindow)
            jWindow.setMinimumSize(java.awt.Dimension(figPos(3), figPos(4)));
        end
    catch ME %#ok<NASGU>
    end
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
        
        if chosen
            guidata(handles.figure, handles);
            setpref('Symphony', 'LastChosenProtocol', pluginClassName);
        end
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


function windowDidResize(~, ~, handles)

    figPos = get(handles.figure, 'Position');
    figWidth = ceil(figPos(3));
    figHeight = ceil(figPos(4));
    
    % Keep the start, stop and save epochs controls in the upper left corner.
    startPos = get(handles.startButton, 'Position');
    startPos(2) = figHeight - 10 - startPos(4);
    set(handles.startButton, 'Position', startPos);
    stopPos = get(handles.stopButton, 'Position');
    stopPos(1) = startPos(1) + startPos(3);
    stopPos(2) = figHeight - 10 - stopPos(4);
    set(handles.stopButton, 'Position', stopPos);
    savePos = get(handles.saveEpochsCheckbox, 'Position');
    savePos(2) = startPos(2) - 10 - savePos(4);
    set(handles.saveEpochsCheckbox, 'Position', savePos);
    
    % Keep the protocol controls in the upper right corner.
    popupPos = get(handles.protocolPopup, 'Position');
    popupPos(1) = figWidth - 10 - popupPos(3);
    popupPos(2) = figHeight - 10 - popupPos(4);
    set(handles.protocolPopup, 'Position', popupPos);
    labelPos = get(handles.protocolLabel, 'Position');
    labelPos(1) = popupPos(1) - 5 - labelPos(3);
    labelPos(2) = figHeight - 10 - labelPos(4);
    set(handles.protocolLabel, 'Position', labelPos);
    
    % Keep the keywords controls at the top and full width.
    keywordsLabelPos = get(handles.keywordsLabel, 'Position');
    keywordsLabelPos(2) = savePos(2) - 10 - keywordsLabelPos(4);
    set(handles.keywordsLabel, 'Position', keywordsLabelPos);
    keywordsPos = get(handles.keywordsEdit, 'Position');
    keywordsPos(2) = savePos(2) - 10 - keywordsPos(4) + 4;
    keywordsPos(3) = figWidth - 10 - keywordsPos(1) - 10;
    set(handles.keywordsEdit, 'Position', keywordsPos);
    
    % Expand the epoch group controls to the full width and height.
    epochPanelPos = get(handles.epochPanel, 'Position');
    epochPanelPos(3) = figWidth - 10 - epochPanelPos(1) - 10;
    epochPanelPos(4) = keywordsPos(2) - 10 - epochPanelPos(2);
    set(handles.epochPanel, 'Position', epochPanelPos);
    outputPathPos = get(handles.epochGroupOutputPathText, 'Position');
    outputPathPos(3) = epochPanelPos(3) - 10 - outputPathPos(1);
    set(handles.epochGroupOutputPathText, 'Position', outputPathPos);
    labelPos = get(handles.epochGroupLabelText, 'Position');
    labelPos(3) = epochPanelPos(3) - 10 - labelPos(1);
    set(handles.epochGroupLabelText, 'Position', labelPos);
    sourcePos = get(handles.epochGroupSourceText, 'Position');
    sourcePos(3) = epochPanelPos(3) - 10 - sourcePos(1);
    set(handles.epochGroupSourceText, 'Position', sourcePos);
    newGroupPos = get(handles.newEpochGroupButton, 'Position');
    newGroupPos(1) = epochPanelPos(3) - 10 - newGroupPos(3);
    set(handles.newEpochGroupButton, 'Position', newGroupPos);
end


%% Protocol starting/stopping


function startAcquisition(~, ~, handles)
    if chooseProtocol([], [], handles)
        handles = guidata(handles.figure);
    else
        return
    end
    
    % Disable/enable the appropriate GUI
    set([handles.startButton, handles.protocolPopup, handles.saveEpochsCheckbox, handles.newEpochGroupButton], 'Enable', 'off');
    set(handles.stopButton, 'Enable', 'on');
    
    handles.stopProtocol = false;
    guidata(handles.figure, handles);
    
    % Wrap the rest in a try/catch block so we can be sure to reenable the GUI.
    try
        import Symphony.Core.*;
    
        rootPath = get(handles.epochGroupOutputPathText, 'String');
        rigName = 'C';      % TODO: add UI to input this
        cellName = 'c1';    % TODO: add UI to input this
        savePath = fullfile(rootPath, [datestr(now, 'mmddyy') rigName cellName '.hdf5']);
        persistor = EpochHDF5Persistor(savePath);

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
        properties = structToDictionary(struct);
        
        runProtocol(handles, persistor, label, parentArray, sourceArray, keywordArray, properties, System.Guid.NewGuid());
    catch ME
        % Reenable the GUI.
        set([handles.startButton, handles.protocolPopup, handles.saveEpochsCheckbox, handles.newEpochGroupButton], 'Enable', 'on');
        set(handles.stopButton, 'Enable', 'off');
        
        rethrow(ME);
    end
    
    % Reenable the GUI.
    set([handles.startButton, handles.protocolPopup, handles.saveEpochsCheckbox, handles.newEpochGroupButton], 'Enable', 'on');
    set(handles.stopButton, 'Enable', 'off');
end


function stopAcquisition(~, ~, handles)
    handles.stopProtocol = true;
    guidata(handles.figure, handles);
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


function runProtocol(handles, persistor, label, parents, sources, keywords, properties, identifier)
    import Symphony.Core.*;
    
    
    handles.figureHandlers = {CurrentResponseFigureHandler(handles.protocolPlugin), MeanResponseFigureHandler(handles.protocolPlugin), ResponseStatisticsFigureHandler(handles.protocolPlugin)};
    guidata(handles.figure, handles);
    
    % Set up the persistor.
    persistor.BeginEpochGroup(label, parents, sources, keywords, properties, identifier);
    
    try
        % Initialize the run.
        handles.protocolPlugin.epoch = [];
        handles.protocolPlugin.epochNum = 0;
        handles.protocolPlugin.prepareEpochGroup()

        % Loop through all of the epochs.
        while handles.protocolPlugin.continueEpochGroup() && ~handles.stopProtocol
            % Create a new epoch.
            handles.protocolPlugin.epochNum = handles.protocolPlugin.epochNum + 1;
            handles.protocolPlugin.epoch = Epoch(handles.protocolPlugin.identifier);

            % Let sub-classes add stimulii, record responses, tweak params, etc.
            handles.protocolPlugin.prepareEpoch();

            % Set the params now that the sub-class has had a chance to tweak them.
            pluginParams = handles.protocolPlugin.parameters();
            fields = fieldnames(pluginParams);
            for fieldName = fields'
                handles.protocolPlugin.epoch.ProtocolParameters.Add(fieldName{1}, pluginParams.(fieldName{1}));
            end

            % Run the epoch.
            try
                handles.protocolPlugin.controller.RunEpoch(handles.protocolPlugin.epoch, persistor);
                
                persistor.Serialize(handles.protocolPlugin.epoch);
                
                for index = 1:numel(handles.figureHandlers)
                    figureHandler = handles.figureHandlers{index};
                    figureHandler.handleCurrentEpoch();
                end
                
                % Force any figures to redraw and any events (clicking the Stop button in particular) to get processed.
                drawnow;
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
            handles.protocolPlugin.completeEpoch();
            
            handles = guidata(handles.figure);
        end
    catch e
        ed = errordlg(e.message);
        waitfor(ed);
    end
    
    % Let the sub-class perform any final analysis, clean up, etc.
    handles.protocolPlugin.completeEpochGroup();
    
    persistor.EndEpochGroup();
    persistor.Close();
end
