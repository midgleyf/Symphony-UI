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
    
    stimuli = handles.protocolCopy.sampleStimuli();
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
        paramProps = findprop(protocol, paramName);
        if paramProps.HasDefault
            defaultValue = paramProps.DefaultValue;
        else
            defaultValue = [];
        end
        
        uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'HorizontalAlignment', 'right', ...
            'Position', [10 dialogHeight-paramIndex*30 labelWidth 18], ...
            'String',  paramLabel,...
            'Style', 'text');
        
        paramTag = [paramName 'Edit'];
        if isinteger(defaultValue) && ~paramProps.Dependent
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'HorizontalAlignment', 'left', ...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 185 26], ...
                'String',  num2str(paramValue),...
                'Style', 'edit', ...
                'Tag', paramTag);
            uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'Position', [labelWidth+201 dialogHeight-paramIndex*30+10 12 12], ...
                'CData', push_cdata, ...
                'Callback', @(hObject,eventdata)stepValueUp(hObject, eventdata, guidata(hObject), paramTag));
            uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'Position', [labelWidth+201 dialogHeight-paramIndex*30-1 12 12], ...
                'CData', flipdim(push_cdata, 1), ...
                'Callback', @(hObject,eventdata)stepValueDown(hObject, eventdata, guidata(hObject), paramTag));
            
            textFieldParamNames{end + 1} = paramName; %#ok<AGROW>
        elseif islogical(defaultValue)
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 200 26], ...
                'Callback', @(hObject,eventdata)checkboxToggled(hObject, eventdata, guidata(hObject)), ...
                'Value', paramValue, ...
                'Style', 'checkbox', ...
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
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 200 26], ...
                'String',  paramValue,...
                'Style', 'edit', ...
                'Tag', paramTag);
            
            textFieldParamNames{end + 1} = paramName; %#ok<AGROW>
        elseif iscellstr(defaultValue) || (iscell(defaultValue) && all(cellfun(@isnumeric, defaultValue)))
            % Default to the first item in the pop-up if nothing has been chosen yet.
            if iscell(paramValue)
                paramValue = paramValue{1};
                params.(paramName) = paramValue;
                handles.protocolCopy.(paramName) = paramValue;
            end
            
            % Figure out which item to select.
            if iscellstr(defaultValue)
                popupValue = find(strcmp(defaultValue, paramValue));
            else
                popupValue = find(cell2mat(defaultValue) == paramValue);
            end
            if isempty(popupValue)
                popupValue = 1;
            end
            
            % Convert the items to human readable form.
            for i = 1:length(defaultValue)
                if ischar(defaultValue{i})
                    defaultValue{i} = humanReadableParameterName(defaultValue{i});
                else
                    defaultValue{i} = num2str(defaultValue{i});
                end
            end
            
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure, ...
                'Units', 'points', ...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 200 22], ...
                'Callback', @(hObject,eventdata)popUpMenuChanged(hObject, eventdata, guidata(hObject)), ...
                'String', defaultValue, ...
                'Style', 'popupmenu', ...
                'Value', popupValue, ...
                'Tag', paramTag);
        else
            error('Unhandled param type for param ''%s''', paramName);
        end
        
        if paramProps.Dependent
            set(handles.(paramTag), 'Enable', 'off');
        end
    end
    
    % TODO: add save/load settings functionality
    
    if handles.showStimuli
        % Create axes for displaying sample stimuli.
        figure(handles.figure);
        handles.stimuliAxes = axes('Units', 'points', 'Position', [labelWidth + 225 + 30 40 axesHeight axesHeight - 10]);
        updateStimuli(handles);
    end
    
    handles.resetButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)useDefaultParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 10 56 20], ...
        'String', 'Reset', ...
        'TooltipString', 'Restore the default parameters', ...
        'Tag', 'resetButton');
    
    handles.cancelButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)cancelEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [labelWidth + 225 - 56 - 10 - 56 - 10 10 56 20], ...
        'String', 'Cancel', ...
        'Tag', 'cancelButton');
    
    handles.saveButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)saveEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [labelWidth + 225 - 10 - 56 10 56 20], ...
        'String', 'Save', ...
        'Tag', 'saveButton');
    
    guidata(handles.figure, handles);
    
    % Try to add Java callbacks so that the stimuli and dependent values can be updated as new values are being typed.
    drawnow
    for i = 1:length(textFieldParamNames)
        paramName = textFieldParamNames{i};
        hObject = handles.([paramName 'Edit']);
        try
            javaHandle = findjobj(hObject);
            set(javaHandle, 'KeyTypedCallback', {@valueChanged, hObject, paramName});
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
        stimuli = handles.protocolCopy.sampleStimuli();
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
    paramProps = findprop(handles.protocol, paramName);
    if paramProps.HasDefault
        defaultValue = paramProps.DefaultValue;
    else
        defaultValue = [];
    end
    javaHandle = findjobj(handles.(paramTag));
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
        values = paramProps.DefaultValue;
        value = values{get(handles.(paramTag), 'Value')};
    elseif ischar(defaultValue)
        value = get(javaHandle, 'Text');
    end
end


function setParamValueInUI(handles, paramName, value)
    paramTag = [paramName 'Edit'];
    paramProps = findprop(handles.protocol, paramName);
    if paramProps.HasDefault
        defaultValue = paramProps.DefaultValue;
    else
        defaultValue = [];
    end
    if iscell(defaultValue)
        paramProps = findprop(handles.protocol, paramName);
        values = paramProps.DefaultValue;
        if ischar(values{1})
            set(handles.(paramTag), 'Value', find(strcmp(values, value)));
        else
            set(handles.(paramTag), 'Value', find(cell2mat(values) == value));
        end
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
    % Push all values into the copy of the plug-in.
    params = handles.protocolCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramProps = findprop(handles.protocolCopy, paramName);
        if ~paramProps.Dependent
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
        paramProps = findprop(handles.protocolCopy, paramName);
        
        if paramProps.Dependent
            setParamValueInUI(handles, paramName, paramValue);
        end
        
        if paramProps.Dependent
            paramTag = [paramName 'Edit'];
            set(handles.(paramTag), 'Enable', 'off');
        end
    end
end


function editParametersKeyPress(hObject, eventdata, handles)
    if strcmp(eventdata.Key, 'return')
        % Move focus off of any edit text so the changes can be seen.
        uicontrol(handles.saveButton);
        
        saveEditParameters(hObject, eventdata, handles);
    elseif strcmp(eventdata.Key, 'escape')
        cancelEditParameters(hObject, eventdata, handles);
    else
        updateDependentValues(handles);
        updateStimuli(handles);
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
        drawnow
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


function useDefaultParameters(~, ~, handles)
    % Reset each independent parameter to its default value.
    params = handles.protocolCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramProps = findprop(handles.protocol, paramName);
        if paramProps.HasDefault
            defaultValue = paramProps.DefaultValue;
        else
            defaultValue = [];
        end
        if iscell(defaultValue)
            defaultValue = defaultValue{1};
        end
        if ~paramProps.Dependent
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


function saveEditParameters(~, ~, handles)
    params = handles.protocol.parameters();
    paramNames = sort(fieldnames(params));
    paramCount = numel(paramNames);
    
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramTag = [paramName 'Edit'];
        paramProps = findprop(handles.protocol, paramName);
        if paramProps.HasDefault
            defaultValue = paramProps.DefaultValue;
        else
            defaultValue = [];
        end
        if ~paramProps.Dependent
            if isnumeric(defaultValue)
                if length(defaultValue) > 1
                    paramValue = str2num(get(handles.(paramTag), 'String')); %#ok<ST2NM>
                else
                    paramValue = str2double(get(handles.(paramTag), 'String'));
                end
                convFunc = str2func(class(paramProps.DefaultValue));
                paramValue = convFunc(paramValue);
            elseif islogical(defaultValue)
                paramValue = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
            elseif iscell(defaultValue)
                paramProps = findprop(handles.protocol, paramName);
                values = paramProps.DefaultValue;
                paramValue = values{get(handles.(paramTag), 'Value')};
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
        throw(ME);
    end
    
    % Remember these parameters for the next time the protocol is used.
    setpref('Symphony', [class(handles.protocol) '_Defaults'], handles.protocol.parameters());
    
    handles.edited = true;
    guidata(handles.figure, handles);
    uiresume;
end
