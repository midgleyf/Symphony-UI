classdef Symphony < handle
    
    properties
        mainWindow                  % Figure handle of the main window
        controller                  % The Symphony.Core.Controller instance.
        protocolClassNames          % The list of protocol class names.
        protocol                    % The current protocol instance.
        figureHandlerClasses        % The list of available figure handlers.
        sources                     % The hierarchy of sources.
        controls                    % A structure containing the handles for most of the controls in the UI.
        rigNames
        commander
        amp_chan1
        persistPath
        persistor                   % The Symphony.EpochPersistor instance.
        epochGroup                  % A structure containing the current epoch group's properties.
        wasSavingEpochs
        metadataDoc
        metadataNode
        notesNode
    end
    
    
    methods
        
        function obj = Symphony()
            import Symphony.Core.*;
            
            obj = obj@handle();
            
            symphonyDir = fileparts(mfilename('fullpath'));
            symphonyParentDir = fileparts(symphonyDir);
            Logging.ConfigureLogging(fullfile(symphonyDir, 'debug_log.xml'), symphonyParentDir);
            
            % Create the controller.
            try
                obj.createSymphonyController('heka', 10000);
            catch ME
                if strcmp(ME.identifier, 'MATLAB:undefinedVarOrClass')
                    % The Heka controller is unavaible (probably on a Mac), use the simulator instead.
                    obj.createSymphonyController('simulation', 10000);
                else
                    rethrow(ME);
                end
            end
            
            % See what protocols, figure handlers and sources are available.
            obj.discoverProtocols();
            obj.discoverFigureHandlers();
            obj.discoverSources();
            
            % Create and open the main window.
            obj.showMainWindow();
            
            obj.updateUIState();
        end
        
        
        function createSymphonyController(obj, daqName, sampleRateInHz)
            import Symphony.Core.*;
            import Symphony.ExternalDevices.*;
            
            % Create Symphony.Core.Controller
            
            obj.controller = Controller();
            
            sampleRate = Measurement(sampleRateInHz, 'Hz');
            
            if strcmpi(daqName, 'heka')
                import Heka.*;
                
                % Register Unit Converters
                HekaDAQInputStream.RegisterConverters();
                HekaDAQOutputStream.RegisterConverters();
                
                daq = HekaDAQController(1, 0); %PCI18 = 1, USB18=5
                daq.InitHardware();
                
                % Finding input and output streams by name
                outStream = daq.GetStream('ANALOG_OUT.0');
                inStream = daq.GetStream('ANALOG_IN.0');
%                 triggerStream = daq.GetStream('DIGITAL_OUT.0');
                
                % Create the MultiClamp device
                obj.commander = MultiClampCommander(831400, 1, daq);
                dev = MultiClampDevice(obj.commander, obj.controller, Measurement(0, 'V'));
                dev.Name = 'test-device';
                dev.Clock = daq;
                dev.BindStream(inStream);
                dev.BindStream(outStream);
                
                % Make sure the user toggles the MultiClamp mode so the data gets telegraphed.
                mode = '';
                while isempty(mode) || ~(strcmp(mode, 'VClamp') || strcmp(mode, 'I0') || strcmp(mode, 'IClamp'))
                    gotMode = false;
                    try
                        mode = char(dev.DeviceParametersForInput(System.DateTimeOffset.Now).Data.OperatingMode);
                        if strcmp(mode, 'VClamp') || strcmp(mode, 'I0') || strcmp(mode, 'IClamp')
                            gotMode = true;
                        end
                    catch ME %#ok<NASGU>
                    end

                    if ~gotMode
                        waitfor(warndlg('Please toggle the MultiClamp commander mode.', 'Symphony', 'modal'));
                    end
                end
            elseif strcmpi(daqName, 'simulation')
                
                import Symphony.SimulationDAQController.*;
                Converters.Register('V','V', @(m) m);
                daq = SimulationDAQController();
                daq.BeginSetup();
                
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
                
%                 triggerStream = DAQOutputStream('TRIGGER');
%                 triggerStream.SampleRate = sampleRate;
%                 triggerStream.MeasurementConversionTarget = 'V';
%                 triggerStream.Clock = daq;
%                 daq.AddStream(triggerStream);
                
                daq.SimulationRunner = Simulation(@(output,step) loopbackSimulation(obj, output, step, outStream, inStream));
                
                dev = UnitConvertingExternalDevice('test-device', 'Tektronix', obj.controller, Measurement(0, 'V'));
                dev.MeasurementConversionTarget = 'V';
                dev.Clock = daq;
                dev.BindStream(inStream);
                dev.BindStream(outStream);
            else
                error(['Unknown daqName: ' daqName]);
            end
            
            daq.Clock = daq;
            obj.controller.DAQController = daq;
            obj.controller.Clock = daq;
            
            % Create the 'trigger' device.
%             triggerDev = UnitConvertingExternalDevice('trigger', 'Tektronix', obj.controller, Measurement(0, 'V'));
%             triggerDev.MeasurementConversionTarget = 'V';
%             triggerDev.Clock = daq;
%             triggerDev.BindStream(triggerStream);
            
            % Have all devices start emitting their background values.
            daq.SetStreamsBackground();
        end
        
        
        function input = loopbackSimulation(obj, output, ~, outStream, inStream)
            import Symphony.Core.*;
            
            input = NET.createGeneric('System.Collections.Generic.Dictionary', {'Symphony.Core.IDAQInputStream','Symphony.Core.IInputData'});
            outData = output.Item(outStream);
            inData = InputData(outData.Data, outData.SampleRate, obj.controller.Clock.Now);
            input.Add(inStream, inData);
        end
        
        
        %% Protocols
        
        
        function discoverProtocols(obj)
            % Get the list of protocols from the 'Protocols' folder.
            symphonyPath = mfilename('fullpath');
            parentDir = fileparts(symphonyPath);
            protocolsDir = fullfile(parentDir, 'Protocols');
            protocolDirs = dir(protocolsDir);
            obj.protocolClassNames = cell(length(protocolsDir), 1);
            protocolCount = 0;
            for i = 1:length(protocolDirs)
                if protocolDirs(i).isdir && ~strcmp(protocolDirs(i).name, '.') && ~strcmp(protocolDirs(i).name, '..') && ~strcmp(protocolDirs(i).name, '.svn')
                    protocolCount = protocolCount + 1;
                    obj.protocolClassNames{protocolCount} = protocolDirs(i).name;
                    addpath(fullfile(protocolsDir, filesep, protocolDirs(i).name));
                end
            end
            obj.protocolClassNames = sort(obj.protocolClassNames(1:protocolCount)); % TODO: use display names
        end
        
        
        function newProtocol = createProtocol(obj, className)
            % Create an instance of the protocol class.
            constructor = str2func(className);
            newProtocol = constructor();
            
            newProtocol.controller = obj.controller;
            newProtocol.figureHandlerClasses = obj.figureHandlerClasses;
            
            % Use any previously set parameters.
            params = getpref('Symphony', [className '_Defaults'], struct);
            paramNames = fieldnames(params);
            for i = 1:numel(paramNames)
                paramProps = findprop(newProtocol, paramNames{i});
                if ~isempty(paramProps) && ~paramProps.Dependent
                    newProtocol.(paramNames{i}) = params.(paramNames{i});
                end
            end
            
            addlistener(newProtocol, 'StateChanged', @(source, event)protocolStateChanged(obj, source, event));
        end
        
        
        function protocolStateChanged(obj, ~, ~)
            obj.updateUIState();
        end
        
        
        %% Figure Handlers
        
        
        function discoverFigureHandlers(obj)
            % Get the list of figure handlers from the 'Figure Handlers' folder.
            symphonyPath = mfilename('fullpath');
            parentDir = fileparts(symphonyPath);
            handlersDir = fullfile(parentDir, 'Figure Handlers', '*.m');
            handlerFileNames = dir(handlersDir);
            obj.figureHandlerClasses = containers.Map;
            for i = 1:length(handlerFileNames)
                if ~handlerFileNames(i).isdir && handlerFileNames(i).name(1) ~= '.'
                    className = handlerFileNames(i).name(1:end-2);
                    mcls = meta.class.fromName(className);
                    if ~isempty(mcls)
                        % Get the type name
                        props = mcls.PropertyList;
                        for j = 1:length(props)
                            prop = props(j);
                            if strcmp(prop.Name, 'figureType')
                                typeName = prop.DefaultValue;
                                break;
                            end
                        end
                        
                        obj.figureHandlerClasses(typeName) = className;
                    end
                end
            end
        end
        
        
        %% Sources


        function discoverSources(obj)
            parentDir = fileparts(mfilename('fullpath'));
            fid = fopen(fullfile(parentDir, 'SourceHierarchy.txt'));
            sourceText = fread(fid, '*char');
            fclose(fid);
            
            sourceLines = regexp(sourceText', '\n', 'split')';
            
            obj.sources = Source(sourceLines{1});
            curPath = obj.sources;
            
            for i = 2:length(sourceLines)
                line = sourceLines{i};
                if ~isempty(line)
                    indent = 0;
                    while strcmp(line(1), char(9))
                        line = line(2:end);
                        indent = indent + 1;
                    end
                    curPath = curPath(1:indent);
                    source = Source(line, curPath(end));
                    curPath(end + 1) = source; %#ok<AGROW>
                end
            end
        end
        
        
        %% GUI layout/control
        
        
        function showMainWindow(obj)
            if ~isempty(obj.mainWindow)
                figure(obj.mainWindow);
            else
                import Symphony.Core.*;
                
                if ~isempty(obj.mainWindow)
                    % Bring the existing main window to the front.
                    figure(obj.mainWindow);
                    return;
                end
                
                % Create a default protocol plug-in.
                lastChosenProtocol = getpref('Symphony', 'LastChosenProtocol', obj.protocolClassNames{1});
                protocolValue = find(strcmp(obj.protocolClassNames, lastChosenProtocol));
                obj.protocol = obj.createProtocol(lastChosenProtocol);
                
                obj.wasSavingEpochs = true;
                
                % Restore the window position if possible.
                if ispref('Symphony', 'MainWindow_Position')
                    addlProps = {'Position', getpref('Symphony', 'MainWindow_Position')};
                else
                    addlProps = {};
                end
                
                % Create the user interface.
                obj.mainWindow = figure(...
                    'Units', 'points', ...
                    'Menubar', 'none', ...
                    'Name', 'Symphony', ...
                    'NumberTitle', 'off', ...
                    'ResizeFcn', @(hObject,eventdata)windowDidResize(obj,hObject,eventdata), ...
                    'CloseRequestFcn', @(hObject,eventdata)closeRequestFcn(obj,hObject,eventdata), ...
                    'Position', centerWindowOnScreen(364, 200), ...
                    'UserData', [], ...
                    'Tag', 'figure', ...
                    addlProps{:});
                
                bgColor = get(obj.mainWindow, 'Color');
                
                obj.controls = struct();
                
                % Create the protocol controls.
                
                obj.controls.protocolPanel = uipanel(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Title', 'Protocol', ...
                    'Tag', 'protocolPanel', ...
                    'Clipping', 'on', ...
                    'Position', [10 195 336 84], ...
                    'BackgroundColor', bgColor);
                
                obj.controls.protocolPopup = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)chooseProtocol(obj,hObject,eventdata), ...
                    'Position', [10 42 130 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', obj.protocolClassNames, ...
                    'Style', 'popupmenu', ...
                    'Value', protocolValue, ...
                    'Tag', 'protocolPopup');
                
                obj.controls.editParametersButton = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)editProtocolParameters(obj,hObject,eventdata), ...
                    'Position', [10 10 130 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Edit Parameters...', ...
                    'Tag', 'editParametersButton');
                
                obj.controls.startButton = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)startAcquisition(obj,hObject,eventdata), ...
                    'Position', [170 42 70 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Start', ...
                    'Tag', 'startButton');
                
                obj.controls.pauseButton = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)pauseAcquisition(obj,hObject,eventdata), ...
                    'Enable', 'off', ...
                    'Position', [245 42 70 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Pause', ...
                    'Tag', 'pauseButton');
                
                obj.controls.stopButton = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)stopAcquisition(obj,hObject,eventdata), ...
                    'Enable', 'off', ...
                    'Position', [320 42 70 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Stop', ...
                    'Tag', 'stopButton');
                
                obj.controls.statusLabel = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Callback', @(hObject,eventdata)editProtocolParameters(obj,hObject,eventdata), ...
                    'Position', [170 10 140 18], ...
                    'HorizontalAlignment', 'left', ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Status:', ...
                    'Style', 'text', ...
                    'Tag', 'statusLabel');
                
                % Save epochs checkbox
                
                obj.controls.saveEpochsCheckbox = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Position', [10 170 250 18], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Save Epochs with Group', ...
                    'Value', uint8(obj.protocol.allowSavingEpochs), ...
                    'Style', 'checkbox', ...
                    'Tag', 'saveEpochsCheckbox');
                
                % Create the epoch group controls
                
                obj.controls.epochPanel = uipanel(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Title', 'Epoch Group', ...
                    'Tag', 'uipanel1', ...
                    'Clipping', 'on', ...
                    'Position', [10 10 336 150], ...
                    'BackgroundColor', bgColor);
                
                uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [8 110 67 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Output path:', ...
                    'Style', 'text', ...
                    'Tag', 'text3');
                
                obj.controls.epochGroupOutputPathText = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [78 111 250 14], ...
                    'BackgroundColor', bgColor, ...
                    'String', '', ...
                    'Style', 'text', ...
                    'Tag', 'epochGroupOutputPathText');
                
                uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [8 94 67 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Label:', ...
                    'Style', 'text', ...
                    'Tag', 'text5');
                
                obj.controls.epochGroupLabelText = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [78 95 250 14], ...
                    'BackgroundColor', bgColor, ...
                    'String', '', ...
                    'Style', 'text', ...
                    'Tag', 'epochGroupLabelText');
                
                uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [8 78 67 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Source:', ...
                    'Style', 'text', ...
                    'Tag', 'text7');
                
                obj.controls.epochGroupSourceText = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [78 79 250 14], ...
                    'BackgroundColor', bgColor, ...
                    'String', '', ...
                    'Style', 'text', ...
                    'Tag', 'epochGroupSourceText');
                
                obj.controls.epochKeywordsLabel = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [10 43 170 17.6], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Keywords for future epochs:', ...
                    'Style', 'text', ...
                    'Tag', 'text2');
                
                obj.controls.epochKeywordsEdit = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [190 43 160 26], ...
                    'BackgroundColor', bgColor, ...
                    'String', blanks(0), ...
                    'Style', 'edit', ...
                    'Tag', 'epochKeywordsEdit');
                
                obj.controls.newEpochGroupButton = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)createNewEpochGroup(obj,hObject,eventdata), ...
                    'Position', [10 10 100 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'New...', ...
                    'Tag', 'newEpochGroupButton');
                
                obj.controls.addNoteButton = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)addNote(obj,hObject,eventdata), ...
                    'Position', [117.5 10 100 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Add Note...', ...
                    'Tag', 'addNoteButton');
                
                obj.controls.closeEpochGroupButton = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)closeEpochGroup(obj,hObject,eventdata), ...
                    'Position', [225 10 100 22], ...
                    'BackgroundColor', bgColor, ...
                    'Enable', 'off', ...
                    'String', 'Close', ...
                    'Tag', 'closeEpochGroupButton');
                
                % Attempt to set button images using Java.
                try
                    drawnow
                    
                    % Add images to the start, pause and stop buttons.
                    imagesPath = fullfile(fileparts(mfilename('fullpath')), 'Images');

                    jButton = java(findjobj(obj.controls.startButton));
                    startIconPath = fullfile(imagesPath, 'start.png');
                    jButton.setIcon(javax.swing.ImageIcon(startIconPath));
                    jButton.setHorizontalTextPosition(javax.swing.SwingConstants.RIGHT);

                    jButton = java(findjobj(obj.controls.pauseButton));
                    pauseIconPath = fullfile(imagesPath, 'pause.png');
                    jButton.setIcon(javax.swing.ImageIcon(pauseIconPath));
                    jButton.setHorizontalTextPosition(javax.swing.SwingConstants.RIGHT);

                    jButton = java(findjobj(obj.controls.stopButton));
                    stopIconPath = fullfile(imagesPath, 'stop.png');
                    jButton.setIcon(javax.swing.ImageIcon(stopIconPath));
                    jButton.setHorizontalTextPosition(javax.swing.SwingConstants.RIGHT);
                catch ME %#ok<NASGU>
                end
    
                % Attempt to set the minimum window size using Java.
                try
                    drawnow
                    
                    jFigPeer = get(handle(obj.mainWindow),'JavaFrame');
                    jWindow = jFigPeer.fFigureClient.getWindow;
                    if ~isempty(jWindow)
                        jWindow.setMinimumSize(java.awt.Dimension(540, 280));
                    end
                catch ME %#ok<NASGU>
                end
            end
        end
        
        
        function editProtocolParameters(obj, ~, ~)
            % The user clicked the "Parameters..." button.
            editParameters(obj.protocol);
        end
        
        
        function chooseProtocol(obj, ~, ~)
            % The user chose a protocol from the pop-up.
            
            pluginIndex = get(obj.controls.protocolPopup, 'Value');
            protocolClassName = obj.protocolClassNames{pluginIndex};
            
            % Create a new protocol if the user chose a different protocol class.
            if ~isa(obj.protocol, protocolClassName)
                try
                    newProtocol = obj.createProtocol(protocolClassName);
                catch ME
                    waitfor(errordlg(['Could not create a ''' protocolClassName ''' instance.' char(10) char(10) ME.message], 'Symphony'));
                    newProtocol = [];
                end
                
                if ~isempty(newProtocol) && editParameters(newProtocol)
                    obj.protocol.closeFigures();
                    
                    obj.protocol = newProtocol;
                    setpref('Symphony', 'LastChosenProtocol', protocolClassName);
                    
                    if ~obj.protocol.allowSavingEpochs
                        obj.wasSavingEpochs = get(obj.controls.saveEpochsCheckbox, 'Value') == get(obj.controls.saveEpochsCheckbox, 'Max');
                        set(obj.controls.saveEpochsCheckbox, 'Value', get(obj.controls.saveEpochsCheckbox, 'Min'));
                    elseif obj.wasSavingEpochs
                        set(obj.controls.saveEpochsCheckbox, 'Value', get(obj.controls.saveEpochsCheckbox, 'Max'));
                    end
                else
                    % The user cancelled editing the parameters so switch back to the previous protocol.
                    protocolValue = find(strcmp(obj.protocolClassNames, class(obj.protocol)));
                    set(obj.controls.protocolPopup, 'Value', protocolValue);
                end
            end
        end
        
        
        function windowDidResize(obj, ~, ~)
            figPos = get(obj.mainWindow, 'Position');
            figWidth = ceil(figPos(3));
            figHeight = ceil(figPos(4));
            
            % Expand the protocol panel to the full width and keep it at the top.
            protocolPanelPos = get(obj.controls.protocolPanel, 'Position');
            protocolPanelPos(2) = figHeight - 10 - protocolPanelPos(4);
            protocolPanelPos(3) = figWidth - 10 - 10;
            set(obj.controls.protocolPanel, 'Position', protocolPanelPos);
            
            % Keep the "Save Epochs" checkbox between the two panels.
            saveEpochsPos = get(obj.controls.saveEpochsCheckbox, 'Position');
            saveEpochsPos(2) = protocolPanelPos(2) - 10 - saveEpochsPos(4);
            set(obj.controls.saveEpochsCheckbox, 'Position', saveEpochsPos);
            
            % Expand the epoch group panel to the full width and remaining height.
            epochPanelPos = get(obj.controls.epochPanel, 'Position');
            epochPanelPos(3) = figWidth - 10 - 10;
            epochPanelPos(4) = saveEpochsPos(2) - 10 - epochPanelPos(2);
            set(obj.controls.epochPanel, 'Position', epochPanelPos);
            outputPathPos = get(obj.controls.epochGroupOutputPathText, 'Position');
            outputPathPos(3) = epochPanelPos(3) - 10 - outputPathPos(1);
            set(obj.controls.epochGroupOutputPathText, 'Position', outputPathPos);
            labelPos = get(obj.controls.epochGroupLabelText, 'Position');
            labelPos(3) = epochPanelPos(3) - 10 - labelPos(1);
            set(obj.controls.epochGroupLabelText, 'Position', labelPos);
            sourcePos = get(obj.controls.epochGroupSourceText, 'Position');
            sourcePos(3) = epochPanelPos(3) - 10 - sourcePos(1);
            set(obj.controls.epochGroupSourceText, 'Position', sourcePos);
            epochKeywordsLabelPos = get(obj.controls.epochKeywordsLabel, 'Position');
            epochKeywordsLabelPos(2) = sourcePos(2) - 14 - epochKeywordsLabelPos(4);
            set(obj.controls.epochKeywordsLabel, 'Position', epochKeywordsLabelPos);
            epochKeywordsPos = get(obj.controls.epochKeywordsEdit, 'Position');
            epochKeywordsPos(2) = sourcePos(2) - 12 - epochKeywordsPos(4) + 4;
            epochKeywordsPos(3) = epochPanelPos(3) - 10 - epochKeywordsLabelPos(3) - 10 - 10;
            set(obj.controls.epochKeywordsEdit, 'Position', epochKeywordsPos);
            addNotePos = get(obj.controls.addNoteButton, 'Position');
            addNotePos(1) = (epochPanelPos(3) - addNotePos(3)) / 2.0;
            set(obj.controls.addNoteButton, 'Position', addNotePos);
            closeGroupPos = get(obj.controls.closeEpochGroupButton, 'Position');
            closeGroupPos(1) = epochPanelPos(3) - 14 - closeGroupPos(3);
            set(obj.controls.closeEpochGroupButton, 'Position', closeGroupPos);
        end
        
        
        function updateUIState(obj)
            % Update the state of the UI based on the state of the protocol.
            set(obj.controls.statusLabel, 'String', ['Status: ' obj.protocol.state]);
            
            if strcmp(obj.protocol.state, 'stopped')
                set(obj.controls.startButton, 'String', 'Start');
                set(obj.controls.startButton, 'Enable', 'on');
                set(obj.controls.pauseButton, 'Enable', 'off');
                set(obj.controls.stopButton, 'Enable', 'off');
                set(obj.controls.protocolPopup, 'Enable', 'on');
                set(obj.controls.editParametersButton, 'Enable', 'on');
                set(obj.controls.newEpochGroupButton, 'Enable', 'on');
                if isempty(obj.epochGroup)
                    set(obj.controls.epochKeywordsEdit, 'Enable', 'off');
                    set(obj.controls.addNoteButton, 'Enable', 'off');
                else
                    set(obj.controls.epochKeywordsEdit, 'Enable', 'on');
                    set(obj.controls.addNoteButton, 'Enable', 'on');
                end
                if isempty(obj.persistor)
                    set(obj.controls.closeEpochGroupButton, 'Enable', 'off');
                else
                    set(obj.controls.closeEpochGroupButton, 'Enable', 'on');
                end
                if isempty(obj.epochGroup) || ~obj.protocol.allowSavingEpochs
                    set(obj.controls.saveEpochsCheckbox, 'Enable', 'off');
                else
                    set(obj.controls.saveEpochsCheckbox, 'Enable', 'on');
                end
            else    % running or paused
                set(obj.controls.stopButton, 'Enable', 'on');
                set(obj.controls.protocolPopup, 'Enable', 'off');
                set(obj.controls.saveEpochsCheckbox, 'Enable', 'off');
                set(obj.controls.newEpochGroupButton, 'Enable', 'off');
                set(obj.controls.closeEpochGroupButton, 'Enable', 'off');

                if strcmp(obj.protocol.state, 'running')
                    set(obj.controls.startButton, 'Enable', 'off');
                    set(obj.controls.pauseButton, 'Enable', 'on');
                    set(obj.controls.editParametersButton, 'Enable', 'off');
                    set(obj.controls.epochKeywordsEdit, 'Enable', 'off');
                    set(obj.controls.addNoteButton, 'Enable', 'off');
                elseif strcmp(obj.protocol.state, 'paused')
                    set(obj.controls.startButton, 'String', 'Resume');
                    set(obj.controls.startButton, 'Enable', 'on');
                    set(obj.controls.pauseButton, 'Enable', 'off');
                    set(obj.controls.editParametersButton, 'Enable', 'on');
                    set(obj.controls.epochKeywordsEdit, 'Enable', 'on');
                    set(obj.controls.addNoteButton, 'Enable', 'on');
                end
            end
            
            % Update the epoch group settings.
            if isempty(obj.persistor)
                set(obj.controls.epochGroupOutputPathText, 'String', '');
                set(obj.controls.epochGroupLabelText, 'String', '');
                set(obj.controls.epochGroupSourceText, 'String', '');
                set(obj.controls.closeEpochGroupButton, 'String', 'Close File');
            else
                set(obj.controls.epochGroupOutputPathText, 'String', obj.persistPath);
                if isempty(obj.epochGroup)
                    set(obj.controls.epochGroupLabelText, 'String', '');
                    set(obj.controls.epochGroupSourceText, 'String', '');
                else
                    % Show the 'label' hierarchy.
                    label = obj.epochGroup.label;
                    source = obj.epochGroup.source;
                    parentGroup = obj.epochGroup.parentGroup;
                    while ~isempty(parentGroup)
                        label = [parentGroup.label ' : ' label]; %#ok<AGROW>
                        source = parentGroup.source;
                        parentGroup = parentGroup.parentGroup;
                    end
                    set(obj.controls.epochGroupLabelText, 'String', label);
                    
                    % Show the source hierarchy.
                    sourceText = source.name;
                    curSource = source.parentSource;
                    while ~isempty(curSource)
                        sourceText = [curSource.name ' : ' sourceText]; %#ok<AGROW>
                        curSource = curSource.parentSource;
                    end
                    set(obj.controls.epochGroupSourceText, 'String', sourceText);
                end
                if isempty(obj.epochGroup)
                    set(obj.controls.closeEpochGroupButton, 'String', 'Close File');
                else
                    set(obj.controls.closeEpochGroupButton, 'String', 'End Group');
                end
            end
            
            drawnow expose
        end
        
        
        function closeRequestFcn(obj, ~, ~)
            obj.protocol.closeFigures();
            
            if ~isempty(obj.epochGroup)
                while ~isempty(obj.persistor)
                    obj.closeEpochGroup();
                end
            end
            
            % Break the reference loop on the source hierarchy so it gets deleted.
            delete(obj.sources);
            
            % Release any hold we have on hardware.
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.CloseHardware();
            end
            
            % Remember the window position.
            setpref('Symphony', 'MainWindow_Position', get(obj.mainWindow, 'Position'));
            delete(obj.mainWindow);
            
            clear global symphonyInstance
            delete(obj);
        end
        
        
        %% Epoch groups
        
        
        function createNewEpochGroup(obj, ~, ~)
            import Symphony.Core.*;
            
            group = newEpochGroup(obj.epochGroup, obj.sources, obj.controller.Clock);
            if ~isempty(group)
                if isempty(obj.persistor)
                    % Create the persistor and metadata XML.
                    if ismac
                        obj.persistPath = fullfile(group.outputPath, [group.source.name '.xml']);
                        if exist(obj.persistPath, 'file')
                            errordlg({'A file already exists for that cell and rig.'; 'Please choose different values.'});
                            return
                        end
                        obj.persistor = EpochXMLPersistor(obj.persistPath);
                    else
                        obj.persistPath = fullfile(group.outputPath, [group.source.name '.h5']);
                        if exist(obj.persistPath, 'file')
                            errordlg({'A file already exists for that cell and rig.'; 'Please choose different values.'});
                            return
                        end
                        obj.persistor = EpochHDF5Persistor(obj.persistPath, '');
                    end
                    
                    obj.metadataDoc = com.mathworks.xml.XMLUtils.createDocument('symphony-metadata');
                    obj.metadataNode = obj.metadataDoc.getDocumentElement;
                    
                    % Add the source hierarchy to the metadata.
                    ancestors = group.source.ancestors();
                    ancestors(1).persistToMetadata(obj.metadataNode);
                end
                
                obj.epochGroup = group;
                
                obj.epochGroup.beginPersistence(obj.persistor);
                
                obj.updateUIState();
            end
        end
        
        
        function saveMetadata(obj)
            [pathstr, name, ~] = fileparts(obj.persistPath);
            metadataPath = fullfile(pathstr,[name '_metadata.xml']);
            xmlwrite(metadataPath, obj.metadataDoc);
        end
        
        
        function closeEpochGroup(obj, ~, ~)
            if ~isempty(obj.epochGroup)
                % Clean up the epoch group and persistor.
                obj.epochGroup.endPersistence(obj.persistor);
                
                if isempty(obj.epochGroup.parentGroup)
                    % Break the reference loop on the group hierarchy so they all get deleted.
                    delete(obj.epochGroup);
                    obj.epochGroup = [];
                else
                    obj.epochGroup = obj.epochGroup.parentGroup;
                end
            else
                obj.persistor.CloseDocument();
                obj.persistor = [];
                
                obj.saveMetadata();
                obj.metadataDoc = [];
                obj.metadataNode = [];
                obj.notesNode = [];
            end
            
            obj.updateUIState();
        end
        
        
        %% Notes
        
        
        function addNote(obj, ~, ~)
            noteText = inputdlg('Enter a note:', 'Symphony Note', 4, {''}, 'on');
            
            if ~isempty(noteText)
                noteText2 = '';
                for i = 1:size(noteText{1}, 1)
                    noteText2 = [noteText2 strtrim(noteText{1}(i, :)) char(10)]; %#ok<AGROW>
                end
                noteText2 = noteText2(1:end - 1);   % strip off the last newline
                        
                if isempty(obj.notesNode)
                    obj.notesNode = obj.metadataNode.appendChild(obj.metadataDoc.createElement('notes'));
                end

                noteNode = obj.notesNode.appendChild(obj.metadataDoc.createElement('note'));
                noteNode.setAttribute('time', char(obj.controller.Clock.Now().ToString()));
                noteNode.appendChild(obj.metadataDoc.createTextNode(noteText2));
                
                obj.saveMetadata();
            end
        end
        
        
        %% Protocol starting/pausing/stopping
        
        
        function startAcquisition(obj, ~, ~)
            % Edit the protocol parameters if the user hasn't done so already.
            if ~obj.protocol.parametersEdited
                if ~editParameters(obj.protocol)
                    % The user cancelled.
                    return
                end
            end
            
            saveEpochs = get(obj.controls.saveEpochsCheckbox, 'Value') == get(obj.controls.saveEpochsCheckbox, 'Max');
            if saveEpochs
                obj.protocol.persistor = obj.persistor;
            else
                obj.protocol.persistor = [];
            end
            
            keywordsText = get(obj.controls.epochKeywordsEdit, 'String');
            if isempty(keywordsText)
                obj.protocol.epochKeywords = {};
            else
                obj.protocol.epochKeywords = strtrim(regexp(keywordsText, ',', 'split'));
            end
            
            % Run the protocol wrapped in a try/catch block so we can be sure to re-enable the GUI.
            try
                obj.protocol.run();
            catch ME
                % Reenable the GUI.
                obj.updateUIState();
                
                rethrow(ME);
            end
            
            obj.updateUIState();
        end
        
        
        function pauseAcquisition(obj, ~, ~)
            % The user clicked the Pause button.
            obj.protocol.pause();
        end
        
        
        function stopAcquisition(obj, ~, ~)
            % The user clicked the Stop button.
            obj.protocol.stop();
        end
        
    end
end
