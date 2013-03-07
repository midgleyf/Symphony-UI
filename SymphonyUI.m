%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

classdef SymphonyUI < handle
    
    properties
        mainWindow                  % Figure handle of the main window
        
        rigConfigsDir
        rigConfigClassNames
        rigConfigDisplayNames
        rigConfig
        
        protocolDirPopupNames       % directory names (to look for protocols)
        protocolsDir                % path to directory containing currently listed protocols
        protocolClassNames          % The list of protocol class names.
        protocolDisplayNames
        protocol                    % The current protocol instance.
        
        figureHandlersDir           % path to directory containing additional figure handlers not built-in
        figureHandlerClasses        % The list of available figure handlers.
        
        missingDeviceName
        sourcesFile
        sources                     % The hierarchy of sources.
        controls                    % A structure containing the handles for most of the controls in the UI.
        rigNames
        
        persistPath
        persistor                   % The Symphony.EpochPersistor instance.
        epochGroup                  % A structure containing the current epoch group's properties.
        prevEpochGroup
        wasSavingEpochs
        metadataDoc
        metadataNode
        notesNode
    end
    
    
    methods
        
        function obj = SymphonyUI(rigConfigsDir, protocolsDir, figureHandlersDir, sourcesFile)
            import Symphony.Core.*;
                        
            obj = obj@handle();
            
            symphonyDir = fileparts(mfilename('fullpath'));
            symphonyParentDir = fileparts(symphonyDir);
            if ~exist([symphonyParentDir '/debug_logs'],'dir')
                mkdir(symphonyParentDir,'debug_logs');
            end
            Logging.ConfigureLogging(fullfile(symphonyDir, 'debug_log.xml'), [symphonyParentDir '/debug_logs']);
            
            % Verify the given parameters.
            if ~exist(rigConfigsDir, 'dir')
                error(['rigConfigsDir does not exist: ' rigConfigsDir]);
            end
            if ~exist(protocolsDir, 'dir')
                error(['protocolsDir does not exist: ' protocolsDir]);
            end
            if ~isempty(figureHandlersDir) && ~exist(figureHandlersDir, 'dir')
                error(['figureHandlersDir does not exist: ' figureHandlersDir]); 
            end
            if ~exist(sourcesFile, 'file')
                error(['sourcesFile does not exist: ' sourcesFile]);
            end
            
            obj.rigConfigsDir = rigConfigsDir;
            obj.protocolsDir = protocolsDir;
            obj.figureHandlersDir = figureHandlersDir;
            obj.sourcesFile = sourcesFile;
            
            % See what rig configurations, protocols, figure handlers and sources are available.
            obj.discoverRigConfigurations();
            obj.discoverProtocols();
            obj.discoverFigureHandlers();
            obj.discoverSources();
            
            % Create and open the main window.
            obj.showMainWindow();
            
            obj.updateUIState();
        end
        
        
        %% Rig Configurations
        
        
        function discoverRigConfigurations(obj)    
            % Populate the list of rig configurations from the current rig configurations directory.
            
            % Get the list of files in the directory.
            addpath(obj.rigConfigsDir);
            listing = dir(fullfile(obj.rigConfigsDir, '*.m'));
            
            % Get the list of rig configurations from the list of files.
            obj.rigConfigClassNames = {};
            obj.rigConfigDisplayNames = {};
            for i = 1:length(listing)
                className = listing(i).name(1:end-2);
                if any(strcmp(superclasses(className), 'RigConfiguration'))
                    obj.rigConfigClassNames{end + 1} = className;
                    displayName = classProperty(className, 'displayName');
                    if ~isempty(displayName)
                        obj.rigConfigDisplayNames{end + 1} = displayName;
                    else
                        obj.rigConfigDisplayNames{end + 1} = className;
                    end
                end
            end
                                 
            % Don't allow an empty list of rig configurations.
            if isempty(obj.rigConfigClassNames)
                error(['Could not find any rig configurations in the rigConfigsDir: ' obj.rigConfigsDir]);
            end
        end
        
        
        function chooseRigConfiguration(obj, ~, ~)
            % The user chose a new rig configuration from the pop-up.
            
            % Determine the new selection.
            configIndex = get(obj.controls.rigConfigPopup, 'Value');
            configClassName = obj.rigConfigClassNames{configIndex};
            if isa(obj.rigConfig, configClassName)
                % The current rig config was selected again. No action needed.
                return;
            end
            
            if ~isempty(obj.rigConfig)
                obj.rigConfig.close()
            end
            
            try
                constructor = str2func(configClassName);
                obj.rigConfig = constructor();
            
                setpref('Symphony', 'LastChosenRigConfig', configClassName);
            catch ME
                % The user cancelled editing the parameters so switch back to the previous rig configuration.
                configValue = find(strcmp(obj.rigConfigClassNames, class(obj.rigConfig)));
                set(obj.controls.rigConfigPopup, 'Value', configValue);
                
                waitfor(errordlg(['Could not create the device:' char(10) char(10) ME.message], 'Symphony'));
            end
            
            % Recreate the current protocol with the new rig configuration.
            if ~isempty(obj.protocol)
                obj.protocol.closeFigures();
                pluginIndex = get(obj.controls.protocolPopup, 'Value');
                protocolClassName = obj.protocolClassNames{pluginIndex};
                obj.protocol = obj.createProtocol(protocolClassName); 
            end
            
            obj.checkRigConfigAndProtocol();
        end
        
        
        function showRigConfigurationDescription(obj, ~, ~)
            desc = obj.rigConfig.describeDevices();
            waitfor(msgbox([obj.rigConfig.displayName ':' char(10) char(10) desc], 'Rig Configuration', 'modal'));
        end
        
        
        function checkRigConfigAndProtocol(obj)
            % Check the compatibility of the current rig configuration with the current protocol.
            
            % Clear properties from last check.
            obj.missingDeviceName = '';
            
            if ~isempty(obj.rigConfig) && ~isempty(obj.protocol)
                % Does the current rig configuration contain all the devices required by the current protocol?
                deviceNames = obj.protocol.requiredDeviceNames();
                for i = 1:length(deviceNames)
                    device = obj.rigConfig.deviceWithName(deviceNames{i});
                    if isempty(device)
                        obj.missingDeviceName = deviceNames{i};
                        break;
                    end
                end
            end
            
            obj.updateUIState();
        end
        
        
        %% Protocols
        
        
        function discoverProtocols(obj)
            % Populate the list of protocols from the current protocols directory.
            
            % Determine the selected protocols directory from the protocols directory popup control.
            if ~isempty(obj.controls) && isfield(obj.controls, 'protocolDirPopup')
                popupSelectionIndex = get(obj.controls.protocolDirPopup, 'Value');
                if popupSelectionIndex==2
                    obj.protocolsDir = fileparts(obj.protocolsDir);
                else
                    selectedFolderName = obj.protocolDirPopupNames{popupSelectionIndex};
                    obj.protocolsDir = fullfile(obj.protocolsDir, selectedFolderName);
                end
            end
            
            % Search selected folder for protocol directories to populate protocolPopup menu 
            % and non-protocol directories to populate protocolDirPopup menu
            protocolsDirContents = dir(obj.protocolsDir);
            isProtocol = false(length(protocolsDirContents), 1);
            obj.protocolDirPopupNames = cell(length(protocolsDirContents), 1);
            protocolDirCount = 0;
            for i = 1:length(protocolsDirContents)
                if protocolsDirContents(i).isdir
                    % determine if subdirectory is a symphony protocol
                    % (don't search contents of selected directory (.), parent directory (..), and .svn)
                    if ~ismember(protocolsDirContents(i).name,{'.','..','.svn'})
                        dirContent = dir(fullfile(obj.protocolsDir, protocolsDirContents(i).name));
                        for d = 1:length(dirContent)
                            if ~dirContent(d).isdir && strcmp(dirContent(d).name(end-1:end),'.m') && strcmp(dirContent(d).name(1:end-2),protocolsDirContents(i).name)
                                    isProtocol(i) = true;
                                    break
                            end
                        end
                    end
                    % non-protocol subdirectories
                    if ~isProtocol(i)
                        if ~strcmp(protocolsDirContents(i).name,'.svn')
                            protocolDirCount = protocolDirCount + 1;
                            obj.protocolDirPopupNames{protocolDirCount} = protocolsDirContents(i).name;
                        end
                    end
                end
            end
            obj.protocolDirPopupNames = obj.protocolDirPopupNames(1:protocolDirCount);
            % set name of current directory and parent directory in
            % protocolDirPopup menu to something more informative than '.' and '..'
            [parentDir, currentProtocolsDirName, ext] = fileparts(obj.protocolsDir);
            currentProtocolsDirName = [currentProtocolsDirName ext];
            [~, protocolsDirParentName] = fileparts(parentDir);
            obj.protocolDirPopupNames{1} = ['. (' currentProtocolsDirName ')'];
            obj.protocolDirPopupNames{2} = ['.. (' protocolsDirParentName ')'];
            
            % Get protocol class names and display names for protocolPopup menu
            protocolDirs = protocolsDirContents(isProtocol);
            obj.protocolClassNames = cell(length(protocolDirs), 1);
            obj.protocolDisplayNames = cell(length(protocolDirs), 1);
            protocolCount = 0;
            for i = 1:length(protocolDirs)
                if protocolDirs(i).isdir && ~ismember(protocolDirs(i).name,{'.','..','.svn'})
                    protocolCount = protocolCount + 1;
                    className = protocolDirs(i).name;
                    obj.protocolClassNames{protocolCount} = className;
                    addpath(fullfile(obj.protocolsDir, filesep, className));
                    obj.protocolDisplayNames{protocolCount} = classProperty(className, 'displayName');
                    if isempty(obj.protocolDisplayNames{protocolCount})
                        obj.protocolDisplayNames{protocolCount} = className;
                    end
                end
            end
            obj.protocolClassNames = obj.protocolClassNames(1:protocolCount);
            obj.protocolDisplayNames = obj.protocolDisplayNames(1:protocolCount);                
        end
        
        
        function newProtocol = createProtocol(obj, className)           
            % Create an instance of the protocol class.
            constructor = str2func(className);
            newProtocol = constructor();
            newProtocol.rigConfig = obj.rigConfig;
            newProtocol.figureHandlerClasses = obj.figureHandlerClasses;
            
            % Set default or saved values for each parameter.
            savedParams = getpref('Symphony', [className '_Defaults'], struct);
            params = newProtocol.parameters();
            paramNames = fieldnames(params);
            for i = 1:numel(paramNames)
                paramName = paramNames{i};
                paramProps = newProtocol.parameterProperty(paramName);
                if paramProps.meta.Dependent
                    % Dependent parameters do not need to be loaded.
                    continue;
                end
                
                defaultValue = paramProps.defaultValue;               
                if iscell(defaultValue) && ~isempty(defaultValue)
                    value = defaultValue{1};
                else
                    value = defaultValue;
                end

                % Is there a saved value for this parameter? If so, override the default value.
                if isfield(savedParams, paramName)
                    savedValue = savedParams.(paramName);
                    
                    if ~iscell(defaultValue)
                        value = savedValue;
                    else
                        % Only set the saved value if it is a member of the default value cell array.
                        if iscellstr(defaultValue)
                            isMember = ~isempty(find(strcmp(defaultValue, savedValue), 1));
                        else
                            isMember = ~isempty(find(cell2mat(defaultValue) == savedValue, 1));
                        end
                        if isMember
                            value = savedValue;
                        end
                    end
                end

                newProtocol.(paramName) = value;
            end
            
            addlistener(newProtocol, 'StateChanged', @(source, event)protocolStateChanged(obj, source, event));
        end
        
        
        function protocolStateChanged(obj, ~, ~)
            obj.updateUIState();
        end
        
        
        %% Figure Handlers
        
        
        function discoverFigureHandlers(obj)
            % Populate the list of figure handlers from the built-in and user defined figure handlers directory.
            
            % Get the list of files from the built-in 'Figure Handlers' directory.
            symphonyPath = mfilename('fullpath');
            parentDir = fileparts(symphonyPath);
            handlersDir = fullfile(parentDir, 'Figure Handlers');
            addpath(handlersDir);
            listing = dir(fullfile(handlersDir, '*.m'));
            
            % Append the list of files from the user defined figure handlers directory.
            if ~isempty(obj.figureHandlersDir)
                addpath(obj.figureHandlersDir);
                listing = [listing; dir(obj.figureHandlersDir)];
            end
            
            % Get the list of figure handlerss from the list of files.
            obj.figureHandlerClasses = containers.Map;
            for i = 1:length(listing)
                if ~listing(i).isdir && listing(i).name(1) ~= '.'
                    className = listing(i).name(1:end-2);
                    if any(strcmp(superclasses(className), 'FigureHandler'))
                        typeName = classProperty(className, 'figureType');
                        if ~isempty(typeName)
                            obj.figureHandlerClasses(typeName) = className;
                        end
                    end
                end
            end
        end
        
        
        %% Sources


        function discoverSources(obj)
            % Populate the list of sources from the current source hierarchy file.
            
            fid = fopen(obj.sourcesFile);
            sourceText = fread(fid, '*char');
            fclose(fid);
            
            sourceLines = regexp(sourceText', '\n', 'split')';
            
            obj.sources = Source('Sources');
            curPath = obj.sources;
            
            for i = 1:length(sourceLines)
                line = sourceLines{i};
                if ~isempty(line)
                    indent = 0;
                    while strcmp(line(1), char(9))
                        line = line(2:end); % strip leading \t
                        indent = indent + 1;
                    end
                    curPath = curPath(1:indent+1);
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
                
                lastChosenRigConfig = getpref('Symphony', 'LastChosenRigConfig', obj.rigConfigClassNames{1});
                rigConfigValue = find(strcmp(obj.rigConfigClassNames, lastChosenRigConfig));
                if isempty(rigConfigValue)
                    % Could not find the last chosen rig config in the current list. Use the first one found instead.
                    lastChosenRigConfig = obj.rigConfigClassNames{1};
                    rigConfigValue = 1;
                end
                constructor = str2func(lastChosenRigConfig);
                try
                    obj.rigConfig = constructor();
                catch ME
                    % Cannot create a rig config the same as the last one chosen by the user.
                    % Try to make a default one instead.
                    disp(['Could not create a ' lastChosenRigConfig '. Error: ' ME.message]);

                    for i = 1:length(obj.rigConfigClassNames)
                        if ~strcmp(obj.rigConfigClassNames{i}, lastChosenRigConfig)
                            constructor = str2func(obj.rigConfigClassNames{i});
                            try
                                obj.rigConfig = constructor();
                                break;
                            catch ME
                                disp(['Could not create a ' obj.rigConfigClassNames{i} '. Error: ' ME.message]);
                            end
                        end
                    end
                end
                
                if isempty(obj.rigConfig)
                    error('Symphony:NoRigConfiguration', 'Could not create a rig configuration.');
                end
                
                % Create a default protocol plug-in.
                
                if ~isempty(obj.protocolClassNames)
                    lastChosenProtocol = getpref('Symphony', 'LastChosenProtocol', obj.protocolClassNames{1});
                    order = 1:length(obj.protocolClassNames);
                    index = find(strcmp(obj.protocolClassNames, lastChosenProtocol));
                    if ~isempty(index)
                        order(index) = [];
                        order = [index order(:)'];
                    end
                    for protocolValue = order
                        try
                            obj.protocol = obj.createProtocol(obj.protocolClassNames{protocolValue});
                            break;
                        catch ME
                            disp(['Could not create a ' obj.protocolClassNames{protocolValue} '(' ME.message ')']);
                        end
                    end
                end
                
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
                    'Position', centerWindowOnScreen(422, 350), ...
                    'UserData', [], ...
                    'Tag', 'figure', ...
                    addlProps{:});
                
                bgColor = get(obj.mainWindow, 'Color');
                
                obj.controls = struct();
                
                % Create the rig configuration controls
                
                obj.controls.rigConfigPanel = uipanel(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Title', 'Rig Configuration', ...
                    'Tag', 'protocolPanel', ...
                    'Clipping', 'on', ...
                    'Position', [10 279 336 50], ...
                    'BackgroundColor', bgColor);
                
                obj.controls.rigConfigPopup = uicontrol(...
                    'Parent', obj.controls.rigConfigPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)chooseRigConfiguration(obj,hObject,eventdata), ...
                    'Position', [10 5 200 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', obj.rigConfigDisplayNames, ...
                    'Style', 'popupmenu', ...
                    'Value', rigConfigValue, ...
                    'Tag', 'rigConfigPopup');
                
                obj.controls.rigDescButton = uicontrol(...
                    'Parent', obj.controls.rigConfigPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)showRigConfigurationDescription(obj,hObject,eventdata), ...
                    'Position', [220 7 22 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', '?', ...
                    'Tag', 'rigDescButton');
                
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
                
                obj.controls.protocolDirPopup = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)chooseProtocolDir(obj,hObject,eventdata), ...
                    'Position', [10 44 130 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', obj.protocolDirPopupNames, ...
                    'Style', 'popupmenu', ...
                    'Value', 1, ...
                    'Tag', 'protocolDirPopup');
                
                if ~isempty(obj.protocolDisplayNames)
                    protocolNames = obj.protocolDisplayNames;
                else
                    protocolNames = {''};
                    protocolValue = 1;
                end
                    
                obj.controls.protocolPopup = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)chooseProtocol(obj,hObject,eventdata), ...
                    'Position', [10 24 130 22], ...
                    'BackgroundColor', bgColor, ...
                    'String', protocolNames, ...
                    'Style', 'popupmenu', ...
                    'Value', protocolValue, ...
                    'Tag', 'protocolPopup');
                
                obj.controls.editParametersButton = uicontrol(...
                    'Parent', obj.controls.protocolPanel, ...
                    'Units', 'points', ...
                    'Callback', @(hObject,eventdata)editProtocolParameters(obj,hObject,eventdata), ...
                    'Position', [10 3 130 22], ...
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
                
                if ~isempty(obj.protocol)
                    allowSavingEpochs = obj.protocol.allowSavingEpochs;
                else
                    allowSavingEpochs = false;
                end
                
                obj.controls.saveEpochsCheckbox = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 12, ...
                    'Position', [10 170 250 18], ...
                    'BackgroundColor', bgColor, ...
                    'String', 'Save Epochs with Group', ...
                    'Value', allowSavingEpochs, ...
                    'Style', 'checkbox', ...
                    'Tag', 'saveEpochsCheckbox');
                
                obj.controls.notSavingEpochsText = uicontrol(...
                    'Parent', obj.mainWindow, ...
                    'Units', 'points', ...
                    'FontSize', 18, ...
                    'HorizontalAlignment', 'right', ...
                    'Position', [85 110 270 20], ...
                    'BackgroundColor', bgColor, ...
                    'ForegroundColor', 'red', ...
                    'Visible', 'off', ...
                    'String', 'Epoch data is not being saved', ...
                    'Style', 'text', ...
                    'Tag', 'notSavingEpochsText');
                addlistener(obj.controls.saveEpochsCheckbox, 'Value', 'PostSet', @obj.updateUIState);
                
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
                    'Callback', @(hObject,eventdata)promptForNote(obj,hObject,eventdata), ...
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
                    if verLessThan('matlab', '7.14')
                        jWindow = jFigPeer.fFigureClient.getWindow;
                    else
                        jWindow = jFigPeer.fHG1Client.getWindow;
                    end
                    if ~isempty(jWindow)
                        jWindow.setMinimumSize(java.awt.Dimension(540, 370));
                    end
                catch ME %#ok<NASGU>
                end
                
                obj.checkRigConfigAndProtocol();
            end
        end
        
        
        function chooseProtocolDir(obj, ~, ~)
            % The user chose a new directory from the pop-up.
            
            % Get the list of protocols from the selected folder.
            if get(obj.controls.protocolDirPopup, 'Value')==1
                % user selected the current directory of protocols
                return
            end
            obj.discoverProtocols(); % gets the names of protocol and non-protocol subdirectories from the selected folder
            set(obj.controls.protocolDirPopup, 'String', obj.protocolDirPopupNames, 'Value', 1);
            set(obj.controls.protocolPopup, 'Value', 1);
            if isempty(obj.protocolDisplayNames)
                % if there are no protocols in the selected directory
                % the current protocol displayed in protocolPopup menu is an empty string
                set(obj.controls.protocolPopup, 'String', {''});
            else
                % if selected directory contains protocols
                % name of current protocol in protocolPopup is first protocol
                set(obj.controls.protocolPopup, 'String', obj.protocolDisplayNames);
            end
            
            % Choose the protocol but do not display the edit params window.
            obj.chooseProtocol([], [], false);
        end
        
        
        function chooseProtocol(obj, ~, ~, shouldShowParams)
            % The user chose a protocol from the pop-up.
            
            if nargin < 4
                shouldShowParams = true;
            end
            
            if isempty(obj.protocolClassNames)
                % There are no protocols to choose.
                obj.protocol = [];
                obj.checkRigConfigAndProtocol();
                return;
            end
            
            pluginIndex = get(obj.controls.protocolPopup, 'Value');
            protocolClassName = obj.protocolClassNames{pluginIndex};
            
            if isa(obj.protocol, protocolClassName)
                % The current protocol was selected again. No action needed.
                return;
            end
            
            % Create a new protocol.
            try
                newProtocol = obj.createProtocol(protocolClassName);
            catch ME
                waitfor(errordlg(['Could not create a ''' protocolClassName ''' instance.' char(10) char(10) ME.message], 'Symphony'));
                if ~isempty(obj.protocol)
                    protocolValue = find(strcmp(obj.protocolClassNames, class(obj.protocol)));
                else
                    protocolValue = 1;
                end
                set(obj.controls.protocolPopup, 'Value', protocolValue);
                return;
            end

            if ~isempty(obj.protocol)
                obj.protocol.closeFigures();
            end
            oldProtocol = obj.protocol;
            obj.protocol = newProtocol;
            obj.checkRigConfigAndProtocol();

            % Don't show the parameters window if the protocol can't be run (or it's requested not to).
            if shouldShowParams && ~isempty(obj.protocol) && isempty(obj.missingDeviceName)
                if editParameters(obj.protocol)
                    setpref('Symphony', 'LastChosenProtocol', protocolClassName);

                    if ~obj.protocol.allowSavingEpochs
                        obj.wasSavingEpochs = get(obj.controls.saveEpochsCheckbox, 'Value') == get(obj.controls.saveEpochsCheckbox, 'Max');
                        set(obj.controls.saveEpochsCheckbox, 'Value', get(obj.controls.saveEpochsCheckbox, 'Min'));
                    elseif obj.wasSavingEpochs
                        set(obj.controls.saveEpochsCheckbox, 'Value', get(obj.controls.saveEpochsCheckbox, 'Max'));
                    end
                else
                    % User selected cancel on the initial edit params window.
                    % Revert back to the old protocol.
                    obj.protocol = oldProtocol;
                    obj.checkRigConfigAndProtocol();
                    if ~isempty(obj.protocol)
                        protocolValue = find(strcmp(obj.protocolClassNames, class(obj.protocol)));
                    else
                        protocolValue = 1;
                    end
                    set(obj.controls.protocolPopup, 'Value', protocolValue);
                end
            end
        end
        
        
        function editProtocolParameters(obj, ~, ~)
            % The user clicked the "Parameters..." button.
            if editParameters(obj.protocol)
                obj.checkRigConfigAndProtocol();
            end
        end
        
        
        function windowDidResize(obj, ~, ~)
            figPos = get(obj.mainWindow, 'Position');
            figWidth = ceil(figPos(3));
            figHeight = ceil(figPos(4));
            
            % Expand the rig config panel to the full width and keep it at the top.
            rigConfigPanelPos = get(obj.controls.rigConfigPanel, 'Position');
            rigConfigPanelPos(2) = figHeight - 10 - rigConfigPanelPos(4);
            rigConfigPanelPos(3) = figWidth - 10 - 10;
            set(obj.controls.rigConfigPanel, 'Position', rigConfigPanelPos);
            rigDescButtonPos = get(obj.controls.rigDescButton, 'Position');
            rigDescButtonPos(1) = rigConfigPanelPos(3) - rigDescButtonPos(3) - 10;
            set(obj.controls.rigDescButton, 'Position', rigDescButtonPos);
            ripConfigPopupPos = get(obj.controls.rigConfigPopup, 'Position');
            ripConfigPopupPos(3) = rigDescButtonPos(1) - 10;
            set(obj.controls.rigConfigPopup, 'Position', ripConfigPopupPos);
            
            % Expand the protocol panel to the full width and keep it at the top.
            protocolPanelPos = get(obj.controls.protocolPanel, 'Position');
            protocolPanelPos(2) = rigConfigPanelPos(2) - 10 - protocolPanelPos(4);
            protocolPanelPos(3) = figWidth - 10 - 10;
            set(obj.controls.protocolPanel, 'Position', protocolPanelPos);
            statusPos = get(obj.controls.statusLabel, 'Position');
            statusPos(3) = protocolPanelPos(3) - 10 - statusPos(1);
            set(obj.controls.statusLabel, 'Position', statusPos);
            
            % Keep the "Save Epochs" checkbox between the two panels.
            saveEpochsPos = get(obj.controls.saveEpochsCheckbox, 'Position');
            saveEpochsPos(2) = protocolPanelPos(2) - 10 - saveEpochsPos(4);
            set(obj.controls.saveEpochsCheckbox, 'Position', saveEpochsPos);
            notSavingEpochsPos = get(obj.controls.notSavingEpochsText, 'Position');
            notSavingEpochsPos(1) = saveEpochsPos(1) + saveEpochsPos(3) + 10;
            notSavingEpochsPos(3) = figWidth - 10 - notSavingEpochsPos(1);
            notSavingEpochsPos(2) = saveEpochsPos(2);
            set(obj.controls.notSavingEpochsText, 'Position', notSavingEpochsPos);
            
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
        
        
        function updateUIState(obj, varargin)
            % Update the state of the UI based on the state of the protocol.
            if ~isempty(obj.protocol)
                state = obj.protocol.state;
            else
                state = 'No protocol selected.';
            end
            set(obj.controls.statusLabel, 'String', ['Status: ' state]);
            
            if isempty(obj.protocol) || strcmp(obj.protocol.state, 'stopped')
                set(obj.controls.rigConfigPopup, 'Enable', 'on');
                set(obj.controls.startButton, 'String', 'Start');
                if ~isempty(obj.protocol) && isempty(obj.missingDeviceName)
                    set(obj.controls.startButton, 'Enable', 'on');
                    set(obj.controls.editParametersButton, 'Enable', 'on');
                else
                    set(obj.controls.startButton, 'Enable', 'off');
                    set(obj.controls.editParametersButton, 'Enable', 'off');
                    if ~isempty(obj.missingDeviceName)
                        set(obj.controls.statusLabel, 'String', ...
                            ['The protocol cannot be run because there is no ''' obj.missingDeviceName ''' device.']); 
                    end
                end
                set(obj.controls.pauseButton, 'Enable', 'off');
                set(obj.controls.stopButton, 'Enable', 'off');
                set(obj.controls.protocolDirPopup, 'Enable', 'on');
                set(obj.controls.protocolPopup, 'Enable', 'on');
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
                if isempty(obj.protocol) || isempty(obj.epochGroup) || ~obj.protocol.allowSavingEpochs
                    set(obj.controls.saveEpochsCheckbox, 'Enable', 'off');
                else
                    set(obj.controls.saveEpochsCheckbox, 'Enable', 'on');
                end
            else    % running or paused
                set(obj.controls.rigConfigPopup, 'Enable', 'off');
                set(obj.controls.stopButton, 'Enable', 'on');
                set(obj.controls.protocolDirPopup, 'Enable', 'off');
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
            
            saveEpochs = get(obj.controls.saveEpochsCheckbox, 'Value') == get(obj.controls.saveEpochsCheckbox, 'Max');
            if ~isempty(obj.protocol) && ~isempty(obj.epochGroup) && obj.protocol.allowSavingEpochs && ~saveEpochs
                set(obj.controls.notSavingEpochsText, 'Visible', 'on');
            else
                set(obj.controls.notSavingEpochsText, 'Visible', 'off');
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
            % TODO: need to stop the protocol?
            
            if ~isempty(obj.protocol)
                obj.protocol.closeFigures();
            end
            
            if ~isempty(obj.epochGroup)
                while ~isempty(obj.persistor)
                    obj.closeEpochGroup();
                end
            end
            
            % Break the reference loop on the source hierarchy so it gets deleted.
            delete(obj.sources);
            
            % Release any hold we have on hardware.
            if ~isempty(obj.rigConfig)
                obj.rigConfig.close();
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
            
            group = newEpochGroup(obj.epochGroup, obj.sources, obj.prevEpochGroup, obj.rigConfig.controller.Clock);
            if ~isempty(group)
                if isempty(obj.persistor)
                    % Create the persistor and metadata XML.
                    if ismac
                        obj.persistPath = fullfile(group.outputPath, [group.source.name '.xml']);
                    else
                        obj.persistPath = fullfile(group.outputPath, [group.source.name '.h5']);
                    end
                    
                    if exist(obj.persistPath, 'file')
                        choice = questdlg(['This will append to an existing file.' char(10) char(10) 'Do you wish to contiue?'], ...
                                           'Symphony', 'Cancel', 'Continue', 'Continue');
                        if ~strcmp(choice, 'Continue')
                            return
                        end
                    end
                    
                    obj.metadataDoc = com.mathworks.xml.XMLUtils.createDocument('symphony-metadata');
                    obj.metadataNode = obj.metadataDoc.getDocumentElement();
                    
                    if exist(obj.persistPath, 'file')
                        % Make sure we have the same source UUID's as before.
                        [pathstr, name, ~] = fileparts(obj.persistPath);
                        metadataPath = fullfile(pathstr,[name '_metadata.xml']);
                        xmlDoc = xmlread(metadataPath);
                        rootNode = xmlDoc.getDocumentElement();
                        children = rootNode.getChildNodes();
                        for i = 1:children.getLength()
                            childNode = children.item(i - 1);
                            if childNode.getNodeType() == org.w3c.dom.Node.ELEMENT_NODE && ...
                               strcmp(char(childNode.getNodeName()), 'source')
                                obj.sources.childSources(1).syncWithMetadata(childNode);
                                break;
                            end
                        end
                        
                        % Add the source hierarchy to the metadata.
                        group.source.persistToMetadata(obj.metadataNode);
                        
                        % Re-add any notes.
                        noteNodes = rootNode.getElementsByTagName('note');
                        for i = 1:noteNodes.getLength()
                            noteNode = noteNodes.item(i - 1);
                            time = char(noteNode.getAttributes().getNamedItem('time').getNodeValue());
                            obj.addNote(noteNode.getTextContent(), time);
                        end
                    else
                        % Add the source hierarchy to the metadata.
                        group.source.persistToMetadata(obj.metadataNode);
                    end
                    
                    if ismac
                        obj.persistor = EpochXMLPersistor(obj.persistPath);
                    else
                        obj.persistor = EpochHDF5Persistor(obj.persistPath, '', 9);
                    end
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
                    obj.prevEpochGroup = obj.epochGroup;
                    obj.epochGroup = [];
                else
                    obj.epochGroup = obj.epochGroup.parentGroup;
                end
            else
                obj.persistor.CloseDocument();
                obj.persistor = [];
                
                % Break the reference loop on the group hierarchy so they all get deleted.
                delete(obj.prevEpochGroup);
                obj.prevEpochGroup = [];
                
                obj.saveMetadata();
                obj.metadataDoc = [];
                obj.metadataNode = [];
                obj.notesNode = [];
            end
            
            obj.updateUIState();
        end
        
        
        %% Notes
        
        
        function promptForNote(obj, ~, ~)
            noteText = inputdlg('Enter a note:', 'Symphony Note', 4, {''}, 'on');
            
            if ~isempty(noteText)
                noteText2 = '';
                for i = 1:size(noteText{1}, 1)
                    noteText2 = [noteText2 strtrim(noteText{1}(i, :)) char(10)]; %#ok<AGROW>
                end
                noteText2 = noteText2(1:end - 1);   % strip off the last newline
                
                obj.addNote(noteText2);
            end
        end
        
        
        function addNote(obj, noteText, time)
            if nargin == 2
                time = char(obj.rigConfig.controller.Clock.Now().ToString());
            end
            
            if isempty(obj.notesNode)
                obj.notesNode = obj.metadataNode.appendChild(obj.metadataDoc.createElement('notes'));
            end

            noteNode = obj.notesNode.appendChild(obj.metadataDoc.createElement('note'));
            noteNode.setAttribute('time', time);
            noteNode.appendChild(obj.metadataDoc.createTextNode(noteText));
            
            obj.saveMetadata();
        end
        
        
        %% Protocol starting/pausing/stopping
        
        
        function startAcquisition(obj, ~, ~)
            % Edit the protocol parameters if the user hasn't done so already.
            if ~obj.protocol.rigPrepared
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
