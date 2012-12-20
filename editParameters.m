%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function edited = editParameters(protocol)
    handles.protocol = protocol;
    handles.protocolCopy = copy(protocol);
    
    params = protocol.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    
    try
        stimuli = handles.protocolCopy.sampleStimuli();
    catch ME
        warning(['An error occurred when creating sample stimuli:' ME.getReport('extended', 'hyperlinks', 'off')]);
        stimuli = [];
    end
    handles.showStimuli = ~isempty(stimuli);
    
    % TODO: determine the width from the actual labels using textwrap.
    labelWidth = 120;
    
    paramsHeight = paramCount * 30;
    axesHeight = max([paramsHeight 300]);
    dialogHeight = axesHeight + 50;
    
    % Place this dialog on the same screen that the main window is on.
    s = windowScreen(gcf);
    
    % Size the dialog so that the sample axes is square but don't let it be wider than the screen.
    if handles.showStimuli
        bounds = screenBounds(s);
        dpi = get(0, 'ScreenPixelsPerInch');
        bounds = bounds / dpi * 72;
        dialogWidth = min([labelWidth + 225 + 30 + axesHeight + 10, bounds(3) - 20]);
    else
        dialogWidth = labelWidth + 225;
    end
    
    handles.figure = dialog(...
        'Units', 'points', ...
        'Name', [class(protocol) ' Parameters'], ...
        'Position', centerWindowOnScreen(dialogWidth, dialogHeight, s), ...
        'WindowKeyPressFcn', @(hObject, eventdata)editParametersKeyPress(hObject, eventdata, guidata(hObject)), ...
        'Tag', 'figure');
    
    uicontrolcolor = reshape(get(0,'defaultuicontrolbackgroundcolor'), [1,1,3]);
        
    if handles.showStimuli
        % Create axes for displaying sample stimuli.
        figure(handles.figure);
        handles.stimuliAxes = axes('Units', 'points', 'Position', [labelWidth + 225 + 30 40 axesHeight axesHeight - 10]);
        updateStimuli(handles);
    end

    % array for pushbutton's CData
    button_size = 16;
    mid = button_size/2;
    push_cdata = repmat(uicontrolcolor,button_size,button_size);
    for r = 4:11
        start = mid - r + 8 ;
        last = mid + r - 8;
        push_cdata(r,start:last,:) = 0;
    end
        
    % Create a control for each of the protocol's parameters.
    textFieldParamNames = {};
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramValue = params.(paramName);
        paramLabel = humanReadableParameterName(paramName);
        paramProps = protocol.parameterProperty(paramName);
        defaultValue = paramProps.defaultValue;
        
        uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'HorizontalAlignment', 'right', ...
            'Position', [10 dialogHeight-paramIndex*30 labelWidth 18], ...
            'String',  paramLabel,...
            'Style', 'text');
        
        paramTag = [paramName 'Edit'];
        if isinteger(defaultValue) && ~paramProps.meta.Dependent
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'HorizontalAlignment', 'left', ...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 125 26], ...
                'String',  num2str(paramValue),...
                'Style', 'edit', ...
                'TooltipString', paramProps.description, ...
                'Tag', paramTag);
            uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'Position', [labelWidth+141 dialogHeight-paramIndex*30+10 12 12], ...
                'CData', push_cdata, ...
                'Callback', @(hObject,eventdata)stepValueUp(hObject, eventdata, guidata(hObject), paramTag));
            uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'Position', [labelWidth+141 dialogHeight-paramIndex*30-1 12 12], ...
                'CData', flipdim(push_cdata, 1), ...
                'Callback', @(hObject,eventdata)stepValueDown(hObject, eventdata, guidata(hObject), paramTag));
            
            textFieldParamNames{end + 1} = paramName; %#ok<AGROW>
        elseif islogical(defaultValue)
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 140 26], ...
                'Callback', @(hObject,eventdata)checkboxToggled(hObject, eventdata, guidata(hObject)), ...
                'Value', paramValue, ...
                'Style', 'checkbox', ...
                'TooltipString', paramProps.description, ...
                'Tag', paramTag);
        elseif isnumeric(defaultValue) || ischar(defaultValue)
            if isnumeric(defaultValue) && length(defaultValue) > 1
                % Convert a vector of numbers to a comma separated list.
                paramValue = sprintf('%g,', paramValue);
                paramValue = paramValue(1:end-1);
            end
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'HorizontalAlignment', 'left', ...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 140 26], ...
                'String',  paramValue,...
                'Style', 'edit', ...
                'TooltipString', paramProps.description, ...
                'Tag', paramTag);
            
            textFieldParamNames{end + 1} = paramName; %#ok<AGROW>
        elseif iscellstr(defaultValue) || (iscell(defaultValue) && all(cellfun(@isnumeric, defaultValue)))            
            % Figure out which item to select.
            if iscellstr(defaultValue)
                popupValue = find(strcmp(defaultValue, paramValue));
            else
                popupValue = find(cell2mat(defaultValue) == paramValue);
            end
            
            % Convert the items to human readable form.
            for i = 1:length(defaultValue)
                if ischar(defaultValue{i})
                    defaultValue{i} = humanReadableParameterName(defaultValue{i});
                else
                    defaultValue{i} = num2str(defaultValue{i});
                end
            end
            
            % An empty default value should show an empty popup menu.
            if isempty(defaultValue)
                defaultValue = {''};
                popupValue = 1;
            end
            
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure, ...
                'Units', 'points', ...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 140 22], ...
                'Callback', @(hObject,eventdata)popUpMenuChanged(hObject, eventdata, guidata(hObject)), ...
                'String', defaultValue, ...
                'Style', 'popupmenu', ...
                'Value', popupValue, ...
                'TooltipString', paramProps.description, ...
                'Tag', paramTag);
        else
            error('Unhandled param type for param ''%s''', paramName);
        end
        
        % Show units next to parameter if they're defined.
        if ~isempty(paramProps.units)           
            position = get(handles.(paramTag), 'Position');
            unitsLeft = position(1) + position(3) + 5;
            
            % Shift units over to fit up/down stepper if necessary
            if isinteger(defaultValue) && ~paramProps.meta.Dependent
                unitsLeft = unitsLeft + 15;
            end
            
            unitsTag = [paramName 'Units'];
            handles.(unitsTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12, ...
                'HorizontalAlignment', 'left', ...
                'Position', [unitsLeft dialogHeight-paramIndex*30 60 18], ...
                'String', paramProps.units, ...
                'Style', 'text', ...
                'Tag', unitsTag);
        end
        
        if paramProps.meta.Dependent
            set(handles.(paramTag), 'Enable', 'off');
        end
    end
    
    handles.saveButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)saveParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 10 56 20], ...
        'String', 'Save', ...
        'TooltipString', 'Save parameters to file', ...
        'Tag', 'saveButton');    
    
    handles.loadButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)loadParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 + 56 + 5 10 56 20], ...
        'String', 'Load', ...
        'TooltipString', 'Load parameters from file', ...
        'Tag', 'loadButton');
    
    handles.defaultButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)useDefaultParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 + 56 + 5 + 56 + 5  10 56 20], ...
        'String', 'Default', ...
        'TooltipString', 'Restore the default parameters', ...
        'Tag', 'defaultButton');
    
    handles.okButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)okEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [labelWidth + 225 - 56 - 5 - 56 - 10 10 56 20], ...
        'String', 'OK', ...
        'Tag', 'okButton');

    setDefaultButton(handles.figure, handles.okButton);
    
    handles.cancelButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)cancelEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [labelWidth + 225 - 10 - 56 10 56 20], ...
        'String', 'Cancel', ...
        'Tag', 'cancelButton');
    
    guidata(handles.figure, handles);
    
    % Store java handles for quick retrieval.
    drawnow;
    for i = 1:paramCount
        paramName = paramNames{i};
        paramTag = [paramName 'Edit'];
        try
            userData.javaHandle = findjobj(handles.(paramTag));
            set(handles.(paramTag), 'UserData', userData);
        catch ME %#ok<NASGU>
        end
    end
    
    % Try to add Java callbacks so that the stimuli and dependent values can be updated as new values are being typed.
    for i = 1:length(textFieldParamNames)
        paramName = textFieldParamNames{i};
        paramTag = [paramName 'Edit'];
        hObject = handles.(paramTag);
        try
            userData = get(handles.(paramTag), 'UserData');
            set(userData.javaHandle, 'KeyTypedCallback', {@valueChanged, hObject, paramName});
        catch ME %#ok<NASGU>
        end
    end
    
    % Wait for the user to cancel or save.
    uiwait;
    
    if ishandle(handles.figure)
        handles = guidata(handles.figure);
        edited = handles.edited;
        close(handles.figure);
    else
        edited = false;
    end
end


function updateStimuli(handles)
    if handles.showStimuli
        set(handles.figure, 'CurrentAxes', handles.stimuliAxes)
        cla;
        try
            stimuli = handles.protocolCopy.sampleStimuli();
        catch ME
            warning(['An error occurred when creating sample stimuli:' ME.getReport('extended', 'hyperlinks', 'off')]);
            stimuli = [];
        end
        if isempty(stimuli)
            plot3(0, 0, 0);
            set(handles.stimuliAxes, 'XTick', [], 'YTick', [], 'ZTick', [])
            grid on;
            text('Units', 'normalized', 'Position', [0.5 0.5], 'String', 'No samples available', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        else
            stimulusCount = length(stimuli);
            for i = 1:stimulusCount
                stimulus = stimuli{i};
                plot3(ones(1, length(stimulus)) * i, (1:length(stimulus)) / double(handles.protocolCopy.sampleRate), stimulus);
                hold on
            end
            hold off
            set(handles.stimuliAxes, 'XTick', 1:stimulusCount, 'XLim', [0.75 stimulusCount + 0.25])
            xlabel('Sample #');
            ylabel('Time (s)');
            set(gca,'YDir','reverse');
            zlabel('Stimulus');
            grid on;
        end
        axis square;
        title(handles.stimuliAxes, 'Sample Stimuli');
    end
end


function value = getParamValueFromUI(handles, paramName)
    paramTag = [paramName 'Edit'];
    paramProps = handles.protocol.parameterProperty(paramName);
    defaultValue = paramProps.defaultValue;
    
    userData = get(handles.(paramTag), 'UserData');
    javaHandle = userData.javaHandle;
    if isnumeric(defaultValue)
        if length(defaultValue) > 1
            % Convert from a comma separated list, ranges, etc. to a vector of numbers.
            paramValue = str2num(get(javaHandle, 'Text')); %#ok<ST2NM>
        else
            paramValue = str2double(get(javaHandle, 'Text'));
        end
        convFunc = str2func(class(defaultValue));
        value = convFunc(paramValue);
    elseif islogical(defaultValue)
        value = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
    elseif iscell(defaultValue)
        if ~isempty(defaultValue)
            value = defaultValue{get(handles.(paramTag), 'Value')};
        else
            value = {};
        end
    elseif ischar(defaultValue)
        value = get(javaHandle, 'Text');
    end
end


function setParamValueInUI(handles, paramName, value)
    paramTag = [paramName 'Edit'];
    paramProps = handles.protocol.parameterProperty(paramName);
    defaultValue = paramProps.defaultValue;
    
    if iscell(defaultValue)
        values = defaultValue;
        if isempty(values)
            index = 1;
        elseif ischar(values{1})
            index = find(strcmp(values, value));
        else
            index = find(cell2mat(values) == value);
        end
        set(handles.(paramTag), 'Value', index);
    elseif islogical(defaultValue)
        set(handles.(paramTag), 'Value', value);
    elseif ischar(defaultValue)
        set(handles.(paramTag), 'String', value);
    elseif isnumeric(defaultValue)
        if length(defaultValue) > 1
            % Convert a vector of numbers to a comma separated list.
            value = sprintf('%g,', value);
            value = value(1:end-1);
        end
        set(handles.(paramTag), 'String', value);
    end
end


function updateDependentValues(handles)
    % Redraw the GUI to ensure all controls are showing their lastest values before grabbing them.
    drawnow;

    % Push all values into the copy of the plug-in.
    params = handles.protocolCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramProps = handles.protocolCopy.parameterProperty(paramName);
        if ~paramProps.meta.Dependent
            paramValue = getParamValueFromUI(handles, paramName);
            try
                handles.protocolCopy.(paramName) = paramValue;
            catch ME
                % Let the user know why we couldn't set the parameter.
                waitfor(errordlg(ME.message));
                
                % Reset the GUI to the previous value.
                setParamValueInUI(handles, paramName, handles.protocolCopy.(paramName));
            end
        end
    end
    
    % Now update the value of any dependent properties.
    params = handles.protocolCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramValue = params.(paramName);
        paramProps = handles.protocolCopy.parameterProperty(paramName);
        
        if paramProps.meta.Dependent
            setParamValueInUI(handles, paramName, paramValue);
        end
        
        if paramProps.meta.Dependent
            paramTag = [paramName 'Edit'];
            set(handles.(paramTag), 'Enable', 'off');
        end
    end
end


function editParametersKeyPress(hObject, eventdata, handles)
    if strcmp(eventdata.Key, 'return')
        % Move focus off of any edit text so the changes can be seen.
        uicontrol(handles.okButton);
        
        okEditParameters(hObject, eventdata, handles);
    elseif strcmp(eventdata.Key, 'escape')
        cancelEditParameters(hObject, eventdata, handles);
    end
end


function checkboxToggled(~, ~, handles)
    updateDependentValues(handles);
    updateStimuli(handles);
end


function popUpMenuChanged(~, ~, handles)
    updateDependentValues(handles);
    updateStimuli(handles);
end


function valueChanged(~, ~, hObject, paramName)
    handles = guidata(hObject);
    paramValue = getParamValueFromUI(handles, paramName);
    try
        handles.protocolCopy.(paramName) = paramValue;
        updateDependentValues(handles);
        updateStimuli(handles);
    catch ME %#ok<NASGU>
        % The current text may be invalid so just ignore the exception.
    end
end


function stepValueUp(~, ~, handles, paramTag)
    curValue = int32(str2double(get(handles.(paramTag), 'String')));
    set(handles.(paramTag), 'String', num2str(curValue + 1));
    updateDependentValues(handles);
    updateStimuli(handles);
end


function stepValueDown(~, ~, handles, paramTag)
    curValue = int32(str2double(get(handles.(paramTag), 'String')));
    set(handles.(paramTag), 'String', num2str(curValue - 1));
    updateDependentValues(handles);
    updateStimuli(handles);
end


function saveParameters(~, ~, handles)
    paramsDir = findSavedParametersDir(handles);    
    [filename, pathname] = uiputfile([paramsDir '\*.mat'], 'Save Parameters');
    if isequal(filename, 0)
        % User selected cancel.
        return;
    end
    
    params = handles.protocolCopy.parameters();
    save(fullfile(pathname, filename), 'params');
end


function loadParameters(~, ~, handles)
    paramsDir = findSavedParametersDir(handles);
    [filename, pathname] = uigetfile([paramsDir '\*.mat'], 'Load Parameters');
    if isequal(filename, 0)
        % User selected cancel.
        return;
    end
    
    paramsFile = load(fullfile(pathname, filename));
    if ~isfield(paramsFile, 'params')
        errordlg('Parameters file does not contain a params field');
        return;
    end
    
    params = paramsFile.params;
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramProps = handles.protocolCopy.parameterProperty(paramName);
        if isempty(paramProps.meta) || paramProps.meta.Dependent
            % This saved parameter does not need to be loaded.
            continue;
        end
        defaultValue = paramProps.defaultValue;
        
        % Assign the saved value if possible.
        savedValue = params.(paramName);
        if ~iscell(defaultValue)
            handles.protocolCopy.(paramName) = savedValue;
        else
            % Only set the saved value if it is a member of the default value cell array.
            if iscellstr(defaultValue)               
                isMember = ~isempty(find(strcmp(defaultValue, savedValue), 1));
            else
                isMember = ~isempty(find(cell2mat(defaultValue) == savedValue, 1));
            end
            if isMember
                handles.protocolCopy.(paramName) = savedValue;
            end
        end

        setParamValueInUI(handles, paramName, handles.protocolCopy.(paramName));
    end
    
    updateDependentValues(handles);
    updateStimuli(handles);
end


function dir = findSavedParametersDir(handles)
    protocolPath = which(class(handles.protocol));
    protocolDir = fileparts(protocolPath);
    dir = [protocolDir '\saved_parameters'];
    if exist(dir, 'file') ~= 7
        mkdir(dir);
    end
end


function useDefaultParameters(~, ~, handles)
    % Reset each independent parameter to its default value.
    params = handles.protocolCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramProps = handles.protocol.parameterProperty(paramName);
        defaultValue = paramProps.defaultValue;
        
        if iscell(defaultValue)
            if ~isempty(defaultValue)
                defaultValue = defaultValue{1};
            else
                defaultValue = {};
            end
        end
        
        if ~paramProps.meta.Dependent
            handles.protocolCopy.(paramName) = defaultValue;
        end
        
        setParamValueInUI(handles, paramName, defaultValue);
    end
    
    updateDependentValues(handles);
    updateStimuli(handles);
end


function cancelEditParameters(~, ~, handles)
    handles.edited = false;
    guidata(handles.figure, handles);
    uiresume;
end


function okEditParameters(~, ~, handles)
    params = handles.protocol.parameters();
    paramNames = sort(fieldnames(params));
    paramCount = numel(paramNames);
    
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramTag = [paramName 'Edit'];
        paramProps = handles.protocol.parameterProperty(paramName);
        defaultValue = paramProps.defaultValue;
        
        if ~paramProps.meta.Dependent
            if isnumeric(defaultValue)
                if length(defaultValue) > 1
                    paramValue = str2num(get(handles.(paramTag), 'String')); %#ok<ST2NM>
                else
                    paramValue = str2double(get(handles.(paramTag), 'String'));
                end
                convFunc = str2func(class(defaultValue));
                paramValue = convFunc(paramValue);
            elseif islogical(defaultValue)
                paramValue = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
            elseif iscell(defaultValue)
                if ~isempty(defaultValue)
                    paramValue = defaultValue{get(handles.(paramTag), 'Value')};
                else
                    paramValue = {};
                end
            elseif ischar(defaultValue)
                paramValue = get(handles.(paramTag), 'String');
            end
            handles.protocol.(paramName) = paramValue;
        end
    end
    
    try
        % Allow the protocol to apply any of the new settings to the rig.
        handles.protocol.prepareRig();
        handles.protocol.rigConfig.prepared();
        handles.protocol.rigPrepared = true;
    catch ME
        % TODO: What should be done if the rig can't be prepared?
        rethrow(ME);
    end
    
    % Remember these parameters for the next time the protocol is used.
    parameters = handles.protocol.parameters();
    setpref('Symphony', [class(handles.protocol) '_Defaults'], parameters);
    
    handles.edited = true;
    guidata(handles.figure, handles);
    uiresume;
end
