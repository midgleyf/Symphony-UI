classdef Symphony < handle
    
    properties
        mainWindow                  % Figure handle of the main window
        controller                  % The Symphony.Core.Controller instance.
        protocolClassNames          % The list of protocol plug-in names.
        protocolPlugin              % The current protocol plug-in instance.
        figureHandlerClasses        % The list of available figure handlers.
        controls                    % A structure containing the handles for most of the controls in the UI.
        runDisabledControls         % A vector of control handles that should be disabled while a protocol is running.
        stopProtocol                % A flag indicating whether the protocol should stop after the current epoch completes.
        rigNames
        commander
        amp_chan1
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
            
            % See what protocols and figure handlers are available.
            obj.discoverProtocols();
            obj.discoverFigureHandlers();
            
            % The possible values for the name of the rig.
            obj.rigNames = {'A', 'B', 'C'};
            
            % Create and open the main window.
            obj.showMainWindow();
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
                daq.SampleRate = sampleRate;
                
                % Finding input and output streams by name
                outStream = daq.GetStream('ANALOG_OUT.0');
                inStream = daq.GetStream('ANALOG_IN.0');
                
            elseif strcmpi(daqName, 'simulation')
                
                import Symphony.SimulationDAQController.*;
                Converters.Register('V','V', @(m) m);
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
                
                daq.SimulationRunner = Simulation(@(output,step) loopbackSimulation(obj, output, step, outStream, inStream));
                
            else
                error(['Unknown daqName: ' daqName]);
            end
            
            % Setup the MultiClamp device
            % No streams, etc. are required here.  The MultiClamp device is used internally by the Symphony framework to
            % listen for changes from the MultiClamp Commander program.  Those settings are then used to alter the scale
            % and units of responses from the Heka device.
            obj.commander = MultiClampCommander(0, 1, daq); %Using serial 0 for simulation device; was 831400
            obj.amp_chan1 = MultiClampDevice(obj.commander, obj.controller, Measurement(0, 'V'));
            obj.amp_chan1.Clock = daq;
            
            daq.Clock = daq;
            
            obj.controller.DAQController = daq;
            obj.controller.Clock = daq;
            
            % Create external device and bind streams
            dev = UnitConvertingExternalDevice('test-device', obj.controller, Measurement(0, 'V'));
            dev.Clock = daq;
            dev.MeasurementConversionTarget = 'V';
            
            %obj.amp_chan1.BindStream(outStream);
            %obj.amp_chan1.BindStream(inStream);
            
            dev.BindStream(inStream);
            dev.BindStream(outStream);
        end
        
        
        function input = loopbackSimulation(obj, output, ~, outStream, inStream) %#ok<MANU>
            import Symphony.Core.*;
            
            input = NET.createGeneric('System.Collections.Generic.Dictionary', {'Symphony.Core.IDAQInputStream','Symphony.Core.IInputData'});
            outData = output.Item(outStream);
            inData = InputData(outData.Data, outData.SampleRate, System.DateTimeOffset.Now, inStream.Configuration);
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
        
        
        function plugin = createProtocolPlugin(obj, className)
            % Create an instance of the protocol class.
            constructor = str2func(className);
            plugin = constructor();
            
            plugin.controller = obj.controller;
            plugin.figureHandlerClasses = obj.figureHandlerClasses;
            
            % Use any previously set parameters.
            params = getpref('Symphony', [className '_Defaults'], struct);
            paramNames = fieldnames(params);
            for i = 1:numel(paramNames)
                paramProps = findprop(plugin, paramNames{i});
                if ~paramProps.Dependent
                    plugin.(paramNames{i}) = params.(paramNames{i});
                end
            end
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
                        for i = 1:length(props)
                            prop = props(i);
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
                obj.protocolPlugin = obj.createProtocolPlugin(lastChosenProtocol);
                
                % Restore the window position if possible.
                if ispref('Symphony', 'MainWindow_Position')
                    addlProps = {'Position', getpref('Symphony', 'MainWindow_Position')};
                else
                    addlProps = {};
                end
                
                % Get the previously set values for the experiment fields.
                lastChosenMouseID = getpref('Symphony', 'LastChosenMouseID', '');
                lastChosenCellID = getpref('Symphony', 'LastChosenCellID', '');
                lastChosenRig = getpref('Symphony', 'LastChosenRig', obj.rigNames{1});
                rigValue = find(strcmp(obj.rigNames, lastChosenRig));
                
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
                
                obj.controls.startButton = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)startAcquisition(obj,hObject,eventdata), ...
                    'Position', [7.2 252 56 20.8], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Start', ...
                    'Tag', 'startButton');
                
                obj.controls.stopButton = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)stopAcquisition(obj,hObject,eventdata), ...
                    'Enable', 'off', ...
                    'Position', [61.6 252 56 20.8], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Stop', ...
                    'Tag', 'stopButton');
                
                obj.controls.protocolLabel = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [168 255.2 56.8 17.6], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Protocol:', ...
                    'Style', 'text', ...
                    'Tag', 'text1');
                
                obj.controls.protocolPopup = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)chooseProtocol(obj,hObject,eventdata), ...
                    'Position', [224.8 251.2 130.4 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', obj.protocolClassNames, ...
                    'Style', 'popupmenu', ...
                    'Value', protocolValue, ...
                    'Tag', 'protocolPopup');
                
                obj.controls.saveEpochsCheckbox = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Position', [7.2 222.4 100.8 18.4], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Save Epochs', ...
                    'Value', 1, ...
                    'Style', 'checkbox', ...
                    'Tag', 'saveEpochsCheckbox');
                
                obj.controls.editParametersButton = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)editProtocolParameters(obj,hObject,eventdata), ...
                    'Position', [224.8 252 80 20.8], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Parameters...', ...
                    'Tag', 'editParametersButton');
                
                obj.controls.keywordsLabel = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [10.4 192.8 56.8 17.6], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Keywords:', ...
                    'Style', 'text', ...
                    'Tag', 'text2');
                
                obj.controls.keywordsEdit = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [79 189 273 26], ...
                    'BackgroundColor', bgColor, ...
                    'String', blanks(0), ...
                    'Style', 'edit', ...
                    'Tag', 'keywordsEdit');
                
                obj.controls.epochPanel = uipanel(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Title', 'Epoch Group', ...
                    'Tag', 'uipanel1', ...
                    'Clipping', 'on', ...
                    'Position', [13 70 336 111], ...
                    'BackgroundColor', bgColor);
                
                uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [8 74 67 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Output path:', ...
                    'Style', 'text', ...
                    'Tag', 'text3');
                
                obj.controls.epochGroupOutputPathText = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [78 75 250 14], ...
                    'BackgroundColor', bgColor, ...
                    'String', getpref('Symphony', 'EpochGroupOutputPath', ''), ...
                    'Style', 'text', ...
                    'Tag', 'epochGroupOutputPathText');
                
                uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [8 58 67 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Label:', ...
                    'Style', 'text', ...
                    'Tag', 'text5');
                
                obj.controls.epochGroupLabelText = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [78 59 250 14], ...
                    'BackgroundColor', bgColor, ...
                    'String', getpref('Symphony', 'EpochGroupLabel', ''), ...
                    'Style', 'text', ...
                    'Tag', 'epochGroupLabelText');
                
                uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [8 42 67 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Source:', ...
                    'Style', 'text', ...
                    'Tag', 'text7');
                
                obj.controls.epochGroupSourceText = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [78 43 250 14], ...
                    'BackgroundColor', bgColor, ...
                    'String', getpref('Symphony', 'EpochGroupSource', ''), ...
                    'Style', 'text', ...
                    'Tag', 'epochGroupSourceText');
                
                obj.controls.newEpochGroupButton = uicontrol(...
                    'Parent', obj.controls.epochPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)createNewEpochGroup(obj,hObject,eventdata), ...
                    'Position', [224.8 9.6 97.6 20.8], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'New Epoch Group', ...
                    'Tag', 'newEpochGroupButton');
                
                obj.controls.experimentPanel = uipanel(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Title', 'Experiment', ...
                    'Tag', 'experimentPanel', ...
                    'Clipping', 'on', ...
                    'Position', [14.4 16.8 333.6 41.6], ...
                    'BackgroundColor', bgColor);
                
                obj.controls.mouseIDText = uicontrol(...
                    'Parent', obj.controls.experimentPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [5 7 60 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Mouse ID:', ...
                    'Style', 'text', ...
                    'Tag', 'text9');
                
                obj.controls.mouseIDEdit = uicontrol(...
                    'Parent', obj.controls.experimentPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [70 5 75 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', lastChosenMouseID, ...
                    'Style', 'edit', ...
                    'Tag', 'mouseIDEdit');
                
                obj.controls.cellIDText = uicontrol(...
                    'Parent', obj.controls.experimentPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [150 7 60 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Cell:', ...
                    'Style', 'text', ...
                    'Tag', 'cellIDText');
                
                obj.controls.cellIDEdit = uicontrol(...
                    'Parent', obj.controls.experimentPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'left', ...
                    'Position', [215 5 75 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', lastChosenCellID, ...
                    'Style', 'edit', ...
                    'Tag', 'cellIDEdit');
                
                obj.controls.rigText = uicontrol(...
                    'Parent', obj.controls.experimentPanel, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [295 7 60 16], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Rig:', ...
                    'Style', 'text', ...
                    'Tag', 'mouseIDText');
                
                obj.controls.rigPopup = uicontrol(...
                    'Parent', obj.controls.experimentPanel, ...
                    'Units', 'points', ...
                    'Position', [360 2 75 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', obj.rigNames, ...
                    'Style', 'popupmenu', ...
                    'Value', rigValue, ...
                    'Tag', 'rigPopup');
                
                % These controls should be disabled while a protocol is running.
                obj.runDisabledControls = [obj.controls.protocolPopup, obj.controls.saveEpochsCheckbox, obj.controls.editParametersButton, obj.controls.keywordsEdit, ...
                                           obj.controls.newEpochGroupButton, obj.controls.mouseIDEdit, obj.controls.cellIDEdit, obj.controls.rigPopup];
    
                % Attempt to set the minimum window size using Java.
                try
                    drawnow
                    
                    jFigPeer = get(handle(obj.mainWindow),'JavaFrame');
                    jWindow = jFigPeer.fFigureClient.getWindow;
                    if ~isempty(jWindow)
                        jWindow.setMinimumSize(java.awt.Dimension(540, 380));
                    end
                catch ME %#ok<NASGU>
                end
            end
        end
        
        
        function editProtocolParameters(obj, ~, ~)
            % The user clicked the "Parameters..." button.
            editParameters(obj.protocolPlugin);
        end
        
        
        function chooseProtocol(obj, ~, ~)
            % The user chose a protocol from the pop-up.
            
            pluginIndex = get(obj.controls.protocolPopup, 'Value');
            pluginClassName = obj.protocolClassNames{pluginIndex};
            
            % Create a new plugin if the user chose a different protocol.
            if ~isa(obj.protocolPlugin, pluginClassName)
                newPlugin = obj.createProtocolPlugin(pluginClassName);
                
                if editParameters(newPlugin)
                    obj.protocolPlugin.closeFigures();
                    
                    obj.protocolPlugin = newPlugin;
                    setpref('Symphony', 'LastChosenProtocol', pluginClassName);
                else
                    % The user cancelled editing the parameters so switch back to the previous protocol.
                    protocolValue = find(strcmp(obj.protocolClassNames, class(obj.protocolPlugin)));
                    set(obj.controls.protocolPopup, 'Value', protocolValue);
                end
            end
        end
        
        
        function createNewEpochGroup(obj, ~, ~)
            [outputPath, label, source] = newEpochGroup();
            if ~isempty(outputPath)
                set(obj.controls.epochGroupOutputPathText, 'String', outputPath);
                set(obj.controls.epochGroupLabelText, 'String', label);
                set(obj.controls.epochGroupSourceText, 'String', source);
                setpref('Symphony', 'EpochGroupOutputPath', outputPath)
                setpref('Symphony', 'EpochGroupLabel', label)
                setpref('Symphony', 'EpochGroupSource', source)
            end
        end
        
        
        function windowDidResize(obj, ~, ~)
            
            figPos = get(obj.mainWindow, 'Position');
            figWidth = ceil(figPos(3));
            figHeight = ceil(figPos(4));
            
            % Keep the start, stop and save epochs controls in the upper left corner.
            startPos = get(obj.controls.startButton, 'Position');
            startPos(2) = figHeight - 10 - startPos(4);
            set(obj.controls.startButton, 'Position', startPos);
            stopPos = get(obj.controls.stopButton, 'Position');
            stopPos(1) = startPos(1) + startPos(3);
            stopPos(2) = figHeight - 10 - stopPos(4);
            set(obj.controls.stopButton, 'Position', stopPos);
            savePos = get(obj.controls.saveEpochsCheckbox, 'Position');
            savePos(2) = startPos(2) - 10 - savePos(4);
            set(obj.controls.saveEpochsCheckbox, 'Position', savePos);
            
            % Keep the protocol controls in the upper right corner.
            popupPos = get(obj.controls.protocolPopup, 'Position');
            popupPos(1) = figWidth - 10 - popupPos(3);
            popupPos(2) = figHeight - 10 - popupPos(4);
            set(obj.controls.protocolPopup, 'Position', popupPos);
            labelPos = get(obj.controls.protocolLabel, 'Position');
            labelPos(1) = popupPos(1) - 5 - labelPos(3);
            labelPos(2) = figHeight - 10 - labelPos(4);
            set(obj.controls.protocolLabel, 'Position', labelPos);
            buttonPos = get(obj.controls.editParametersButton, 'Position');
            buttonPos(1) = popupPos(1);
            buttonPos(2) = popupPos(2) - 2 - buttonPos(4);
            set(obj.controls.editParametersButton, 'Position', buttonPos);
            
            % Keep the keywords controls at the top and full width.
            keywordsLabelPos = get(obj.controls.keywordsLabel, 'Position');
            keywordsLabelPos(2) = savePos(2) - 10 - keywordsLabelPos(4);
            set(obj.controls.keywordsLabel, 'Position', keywordsLabelPos);
            keywordsPos = get(obj.controls.keywordsEdit, 'Position');
            keywordsPos(2) = savePos(2) - 10 - keywordsPos(4) + 4;
            keywordsPos(3) = figWidth - 10 - keywordsPos(1) - 10;
            set(obj.controls.keywordsEdit, 'Position', keywordsPos);
            
            % Expand the epoch group controls to the full width and height.
            epochPanelPos = get(obj.controls.epochPanel, 'Position');
            epochPanelPos(3) = figWidth - 10 - epochPanelPos(1) - 10;
            epochPanelPos(4) = keywordsPos(2) - 10 - epochPanelPos(2);
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
            newGroupPos = get(obj.controls.newEpochGroupButton, 'Position');
            newGroupPos(1) = epochPanelPos(3) - 10 - newGroupPos(3);
            set(obj.controls.newEpochGroupButton, 'Position', newGroupPos);
            
            % Expand the experiment group controls to the full width and keep them at the bottom.
            experimentPanelPos = get(obj.controls.experimentPanel, 'Position');
            experimentPanelPos(3) = figWidth - 10 - experimentPanelPos(1) - 10;
            set(obj.controls.experimentPanel, 'Position', experimentPanelPos);
            thirdWidth = uint16((experimentPanelPos(3) - 10 * 4) / 3);
            mouseIDLabelPos = get(obj.controls.mouseIDText, 'Position');
            editWidth = thirdWidth - mouseIDLabelPos(3) - 5;
            mouseIDEditPos = get(obj.controls.mouseIDEdit, 'Position');
            mouseIDEditPos(1) = mouseIDLabelPos(1) + mouseIDLabelPos(3) + 5;
            mouseIDEditPos(3) = editWidth;
            set(obj.controls.mouseIDEdit, 'Position', mouseIDEditPos);
            cellIDLabelPos = get(obj.controls.cellIDText, 'Position');
            cellIDLabelPos(1) = mouseIDEditPos(1) + mouseIDEditPos(3) + 10;
            set(obj.controls.cellIDText, 'Position', cellIDLabelPos);
            cellIDEditPos = get(obj.controls.cellIDEdit, 'Position');
            cellIDEditPos(1) = cellIDLabelPos(1) + cellIDLabelPos(3) + 5;
            cellIDEditPos(3) = editWidth;
            set(obj.controls.cellIDEdit, 'Position', cellIDEditPos);
            rigLabelPos = get(obj.controls.rigText, 'Position');
            rigLabelPos(1) = cellIDEditPos(1) + cellIDEditPos(3) + 10;
            set(obj.controls.rigText, 'Position', rigLabelPos);
            rigPopupPos = get(obj.controls.rigPopup, 'Position');
            rigPopupPos(1) = rigLabelPos(1) + rigLabelPos(3) + 5;
            rigPopupPos(3) = editWidth;
            set(obj.controls.rigPopup, 'Position', rigPopupPos);
        end
        
        
        function closeRequestFcn(obj, ~, ~)
            obj.protocolPlugin.closeFigures();
            
            % Release any hold we have on hardware.
            if isa(obj.controller.DAQController, 'Heka.HekaDAQController')
                obj.controller.DAQController.CloseHardware();
            end
            
            % Remember the window position.
            setpref('Symphony', 'MainWindow_Position', get(obj.mainWindow, 'Position'));
            delete(obj.mainWindow);
            
            clear global symphonyInstance
        end
        
        
        %% Protocol starting/stopping
        
        
        function startAcquisition(obj, ~, ~)
            % Edit the protocol parameters if the user hasn't done so already.
            if ~obj.protocolPlugin.parametersEdited
                if ~editParameters(obj.protocolPlugin)
                    % The user cancelled.
                    return
                end
            end
            
            % Disable/enable the appropriate GUI
            set(obj.runDisabledControls, 'Enable', 'off');
            set(obj.controls.startButton, 'Enable', 'off');
            set(obj.controls.stopButton, 'Enable', 'on');
            
            obj.stopProtocol = false;
            
            % Wrap the rest in a try/catch block so we can be sure to re-enable the GUI.
            try
                import Symphony.Core.*;
                
                rootPath = get(obj.controls.epochGroupOutputPathText, 'String');
                
                % Get the experiment values from the UI.
                mouseID = get(obj.controls.mouseIDEdit, 'String');
                cellID = get(obj.controls.cellIDEdit, 'String');
                rigName = obj.rigNames{get(obj.controls.rigPopup, 'Value')};
                
                % Remember what the user chose for next time.
                setpref('Symphony', 'LastChosenMouseID', mouseID);
                setpref('Symphony', 'LastChosenCellID', cellID);
                setpref('Symphony', 'LastChosenRig', rigName);
                
                if get(obj.controls.saveEpochsCheckbox, 'Value') == get(obj.controls.saveEpochsCheckbox, 'Min')
                    persistor = [];
                else
                    % Build the path from the experiment values.
                    savePath = fullfile(rootPath, [datestr(now, 'mmddyy') rigName 'c' cellID '.xml']);
                    persistor = EpochXMLPersistor(savePath);
                end
                
                parentArray = NET.createArray('System.String', 0);
                % TODO: populate parents (from where?)
                
                hierarchy = obj.sourceHierarchy(get(obj.controls.epochGroupSourceText, 'String'));
                sourceArray = NET.createArray('System.String', numel(hierarchy));
                for i = 1:numel(hierarchy)
                    sourceArray(i) = hierarchy{i};
                end
                
                keywordsText = get(obj.controls.keywordsEdit, 'String');
                keywords = strtrim(regexp(keywordsText, ',', 'split'));
                if isequal(keywords, {''})
                    keywords = {};
                end
                keywordArray = NET.createArray('System.String', numel(keywords));
                for i = 1:numel(keywords)
                    keywordArray(i) = keywords{i};
                end
                
                label = get(obj.controls.epochGroupLabelText, 'String');
                properties = structToDictionary(struct('mouseID', mouseID));
                
                obj.runProtocol(persistor, label, parentArray, sourceArray, keywordArray, properties, System.Guid.NewGuid());
            catch ME
                % Reenable the GUI.
                set(obj.runDisabledControls, 'Enable', 'on');
                set(obj.controls.startButton, 'Enable', 'on');
                set(obj.controls.stopButton, 'Enable', 'off');
                
                rethrow(ME);
            end
            
            % Reenable the GUI.
            set(obj.runDisabledControls, 'Enable', 'on');
            set(obj.controls.startButton, 'Enable', 'on');
            set(obj.controls.stopButton, 'Enable', 'off');
        end
        
        
        function stopAcquisition(obj, ~, ~)
            % The user clicked the Stop button.

            % Set a flag that will be checked after the current epoch completes.
            obj.stopProtocol = true;
        end
        
        
        function h = sourceHierarchy(obj, source)
            h = {};
            
            while ~isempty(source)
                h{end + 1} = source; %#ok<AGROW>
                source = obj.sourceParent(source);
            end
        end
        
        
        function p = sourceParent(obj, source) %#ok<MANU>
            if ispref('Symphony', 'Sources')
                sources = getpref('Symphony', 'Sources');
                index = find(strcmp({sources.label}, source));
                p = sources(index).parent; %#ok<FNDSB>
            else
                p = '';
            end
        end
        
        
        function runProtocol(obj, persistor, label, parents, sources, keywords, properties, identifier)
            % This is the core method that runs a protocol, everything else is preparation for this.
            
            import Symphony.Core.*;
            
            % Set up the persistor.
            if ~isempty(persistor)
                persistor.BeginEpochGroup(label, parents, sources, keywords, properties, identifier);
            end
            
            try
                % Initialize the run.
                obj.protocolPlugin.epoch = [];
                obj.protocolPlugin.epochNum = 0;
                obj.protocolPlugin.clearFigures();
                obj.protocolPlugin.prepareEpochGroup()
                
                % Loop through all of the epochs.
                while obj.protocolPlugin.continueEpochGroup() && ~obj.stopProtocol
                    % Create a new epoch.
                    obj.protocolPlugin.epochNum = obj.protocolPlugin.epochNum + 1;
                    obj.protocolPlugin.epoch = Epoch(obj.protocolPlugin.identifier);
                    
                    % Let sub-classes add stimulii, record responses, tweak params, etc.
                    obj.protocolPlugin.prepareEpoch();
                    
                    % Set the params now that the sub-class has had a chance to tweak them.
                    pluginParams = obj.protocolPlugin.parameters();
                    fields = fieldnames(pluginParams);
                    for fieldName = fields'
                        obj.protocolPlugin.epoch.ProtocolParameters.Add(fieldName{1}, pluginParams.(fieldName{1}));
                    end
                    
                    % Run the epoch.
                    try
                        obj.protocolPlugin.controller.RunEpoch(obj.protocolPlugin.epoch, persistor);
                        
                        obj.protocolPlugin.updateFigures();
                        
                        % Force any figures to redraw and any events (clicking the Stop button in particular) to get processed.
                        drawnow;
                    catch e
                        % TODO: is it OK to hold up the run with the error dialog or should errors be logged and displayed at the end?
                        message = ['An error occurred while running the epoch.' char(10) char(10)];
                        if (isa(e, 'NET.NetException'))
                            eObj = e.ExceptionObject;
                            message = [message char(eObj.Message)]; %#ok<AGROW>
                            indent = '    ';
                            while ~isempty(eObj.InnerException)
                                eObj = eObj.InnerException;
                                message = [message char(10) indent char(eObj.Message)]; %#ok<AGROW>
                                indent = [indent '    ']; %#ok<AGROW>
                            end
                        else
                            message = [message e.message]; %#ok<AGROW>
                        end
                        ed = errordlg(message);
                        waitfor(ed);
                    end
                    
                    % Let the sub-class perform any post-epoch analysis, clean up, etc.
                    obj.protocolPlugin.completeEpoch();
                end
            catch e
                ed = errordlg(e.message);
                waitfor(ed);
            end
            
            % Let the sub-class perform any final analysis, clean up, etc.
            obj.protocolPlugin.completeEpochGroup();
            
            if ~isempty(persistor)
                persistor.EndEpochGroup();
                persistor.Close();
            end
        end
        
    end
    
end
