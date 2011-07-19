function edited = editParameters(protocolPlugin)
    handles.protocolPlugin = protocolPlugin;
    handles.pluginCopy = copy(protocolPlugin);
    
    params = protocolPlugin.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    
    % TODO: determine the width from the actual labels.
    labelWidth = 120;
    
    paramsHeight = paramCount * 30;
    axesHeight = max([paramsHeight 300]);
    dialogHeight = axesHeight + 50;
    
    handles.figure = dialog(...
        'Units', 'points', ...
        'Name', [class(protocolPlugin) ' Parameters'], ...
        'Position', centerWindowOnScreen(labelWidth + 225 + 30 + axesHeight + 10, dialogHeight), ...
        'WindowKeyPressFcn', @(hObject, eventdata)editParametersKeyPress(hObject, eventdata, guidata(hObject)), ...
        'Tag', 'figure');
    
    uicontrolcolor = reshape(get(0,'defaultuicontrolbackgroundcolor'),[1,1,3]);

    % array for pushbutton's CData
    button_size = 16;
    mid = button_size/2;
    push_cdata = repmat(uicontrolcolor,button_size,button_size);
    for r = 4:11
        start = mid - r + 8 ;
        last = mid + r - 8;
        push_cdata(r,start:last,:) = 0;
    end
    

    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramValue = params.(paramName);
        paramLabel = humanReadableParameterName(paramName);
        paramProps = findprop(protocolPlugin, paramName);
        
        uicontrol(...
            'Parent', handles.figure,...
            'Units', 'points', ...
            'FontSize', 12,...
            'HorizontalAlignment', 'right', ...
            'Position', [10 dialogHeight-paramIndex*30 labelWidth 18], ...
            'String',  paramLabel,...
            'Style', 'text');
        
        paramTag = [paramName 'Edit'];
        if isinteger(paramValue) && ~paramProps.Dependent
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
        elseif islogical(paramValue)
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 200 26], ...
                'Callback', @(hObject,eventdata)checkboxToggled(hObject, eventdata, guidata(hObject)), ...
                'Value', paramValue, ...
                'Style', 'checkbox', ...
                'Tag', paramTag);
        elseif isnumeric(paramValue) || ischar(paramValue)
            handles.(paramTag) = uicontrol(...
                'Parent', handles.figure,...
                'Units', 'points', ...
                'FontSize', 12,...
                'HorizontalAlignment', 'left', ...
                'Position', [labelWidth+15 dialogHeight-paramIndex*30-2 200 26], ...
                'String',  paramValue,...
                'Style', 'edit', ...
                'Tag', paramTag);
        else
            error('Unhandled param type');
        end
        
        if paramProps.Dependent
            set(handles.(paramTag), 'Enable', 'off');
        end
    end
    
    % TODO: add "Reset to Defaults" button.
    % TODO: add save/load settings functionality
    
    % Create axes for displaying sample stimuli.
    figure(handles.figure);
    handles.stimuliAxes = axes('Units', 'points', 'Position', [labelWidth + 225 + 30 40 axesHeight axesHeight - 10]);
    updateStimuli(handles);
    
    handles.cancelButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)cancelEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 10 56 20], ...
        'String', 'Cancel', ...
        'Tag', 'cancelButton');
    
    handles.saveButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)saveEditParameters(hObject,eventdata,guidata(hObject)), ...
        'Position', [80 10 56 20], ...
        'String', 'Save', ...
        'Tag', 'saveButton');
    
    guidata(handles.figure, handles);
    
    % Wait for the user to cancel or save.
    uiwait;
    
    handles = guidata(handles.figure);
    edited = handles.edited;
    close(handles.figure);
end


function updateStimuli(handles)
    set(handles.figure, 'CurrentAxes', handles.stimuliAxes)
    cla;
    [stimuli, sampleRate] = handles.pluginCopy.sampleStimuli();
    if isempty(stimuli)
        plot3(0, 0, 0);
        set(handles.stimuliAxes, 'XTick', [], 'YTick', [], 'ZTick', [])
        grid on;
        text('Units', 'normalized', 'Position', [0.5 0.5], 'String', 'No samples available', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    else
        stimulusCount = length(stimuli);
        for i = 1:stimulusCount
            stimulus = stimuli{i};
            plot3(ones(1, length(stimulus)) * i, (1:length(stimulus)) / sampleRate, stimulus);
            hold on
        end
        hold off
        set(handles.stimuliAxes, 'XTick', 1:stimulusCount)
        xlabel('Sample #');
        ylabel('Time (s)');
        set(gca,'YDir','reverse');
        zlabel('Stimulus');
        grid on;
    end
    axis square;
    title(handles.stimuliAxes, 'Sample Stimuli');
end


function updateDependentValues(handles)
    % Push all values into the copy of the plug-in.
    params = handles.pluginCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramTag = [paramName 'Edit'];
        paramProps = findprop(handles.pluginCopy, paramName);
        if ~paramProps.Dependent
            if isnumeric(params.(paramName))
                paramValue = str2double(get(handles.(paramTag), 'String'));
                convFunc = str2func(class(params.(paramName)));
                paramValue = convFunc(paramValue);
            elseif islogical(params.(paramName))
                paramValue = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
            elseif ischar(params.(paramName))
                paramValue = get(handles.(paramTag), 'String');
            end
            handles.pluginCopy.(paramName) = paramValue;
        end
    end
    
    % Now update the value of any dependent properties.
    params = handles.pluginCopy.parameters();
    paramNames = fieldnames(params);
    paramCount = numel(paramNames);
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramValue = params.(paramName);
        paramProps = findprop(handles.pluginCopy, paramName);
        paramTag = [paramName 'Edit'];
        
        if paramProps.Dependent
            if islogical(paramValue)
                set(handles.(paramTag), 'Value', paramValue);
            elseif isnumeric(paramValue) || ischar(paramValue)
                set(handles.(paramTag), 'String', paramValue);
            end
        end
        
        if paramProps.Dependent
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


function cancelEditParameters(~, ~, handles)
    handles.edited = false;
    guidata(handles.figure, handles);
    uiresume;
end


function saveEditParameters(~, ~, handles)
    params = handles.protocolPlugin.parameters();
    paramNames = sort(fieldnames(params));
    paramCount = numel(paramNames);
    
    for paramIndex = 1:paramCount
        paramName = paramNames{paramIndex};
        paramTag = [paramName 'Edit'];
        paramProps = findprop(handles.protocolPlugin, paramName);
        if ~paramProps.Dependent
            if isnumeric(params.(paramName))
                paramValue = str2double(get(handles.(paramTag), 'String'));
                convFunc = str2func(class(params.(paramName)));
                paramValue = convFunc(paramValue);
            elseif islogical(params.(paramName))
                paramValue = get(handles.(paramTag), 'Value') == get(handles.(paramTag), 'Max');
            elseif ischar(params.(paramName))
                paramValue = get(handles.(paramTag), 'String');
            end
            handles.protocolPlugin.(paramName) = paramValue;
        end
    end
    
    handles.protocolPlugin.parametersEdited = true;
    
    % Remember these parameters for the next time the protocol is used.
    setpref('Symphony', [class(handles.protocolPlugin) '_Defaults'], handles.protocolPlugin.parameters());
    
    handles.edited = true;
    guidata(handles.figure, handles);
    uiresume;
end
