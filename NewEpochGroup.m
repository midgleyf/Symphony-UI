function [outputPath, label, source] = NewEpochGroup()
    handles.outputPath = '';
    handles.label = '';
    handles.source = '';
    
    handles.figure = dialog(...
        'Units', 'points', ...
        'Name', 'New Epoch Group', ...
        'Position', centerWindowOnScreen(350, 150), ...
        'WindowKeyPressFcn', @(hObject, eventdata)keyPressCallback(hObject, eventdata, guidata(hObject)), ...
        'Tag', 'figure');
    
    % Output path controls
    uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [10 110 100 18], ...
        'String',  'Output path:',...
        'Style', 'text');
    handles.outputPathEdit = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [115 110 195 26], ...
        'String',  '',...
        'Style', 'edit', ...
        'Tag', 'outputPathEdit');
    handles.outputPathButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)pickOutputPath(hObject,eventdata,guidata(hObject)), ...
        'Position', [313 112 25 20], ...
        'String', '...', ...
        'Tag', 'cancelButton');
    
    % Label controls
    uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [10 80 100 18], ...
        'String',  'Label:',...
        'Style', 'text');
    handles.labelEdit = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [115 80 225 26], ...
        'String',  '',...
        'Style', 'edit', ...
        'Tag', 'labelEdit');
    
    % Source controls
    uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'right', ...
        'Position', [10 50 100 18], ...
        'String',  'Source:',...
        'Style', 'text');
    handles.sourcePopup = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'FontSize', 12,...
        'HorizontalAlignment', 'left', ...
        'Position', [115 45 175 26], ...
        'String',  'None',...
        'Style', 'popupmenu', ...
        'Tag', 'sourcePopup');
    handles.newSourceButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)createNewSource(hObject,eventdata,guidata(hObject)), ...
        'Position', [287 52 50 22], ...
        'String', 'New...', ...
        'Tag', 'newSourceButton');
    updateSourcesPopup(handles);
    
    handles.cancelButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)cancelNewGroup(hObject,eventdata,guidata(hObject)), ...
        'Position', [10 10 56 20], ...
        'String', 'Cancel', ...
        'Tag', 'cancelButton');
    
    handles.saveButton = uicontrol(...
        'Parent', handles.figure,...
        'Units', 'points', ...
        'Callback', @(hObject,eventdata)saveNewGroup(hObject,eventdata,guidata(hObject)), ...
        'Position', [80 10 56 20], ...
        'String', 'Save', ...
        'Tag', 'saveButton');
    
    guidata(handles.figure, handles);
    
    uiwait
    
    handles = guidata(handles.figure);
    outputPath = handles.outputPath;
    label = handles.label;
    source = handles.source;
    
    close(handles.figure);
end


function updateSourcesPopup(handles, sourceToSelect)
    if nargin == 1
        sourceToSelect = 'None';
    end
    sources = struct('label', 'None', 'parent', '');
    if ispref('Symphony', 'Sources')
        savedSources = getpref('Symphony', 'Sources');
        sources = horzcat(sources, savedSources);
    end
    labels = sort({sources.label});
    set(handles.sourcePopup, 'String', labels);
    value = find(strcmp(labels, sourceToSelect));
    if isempty(value)
        errordlg(['There is no source with the label ''' sourceToSelect ''''], 'Symphony');
        value = 1;
    end
    set(handles.sourcePopup, 'Value', value);
end


function keyPressCallback(hObject, eventdata, handles)
    if strcmp(eventdata.Key, 'return')
        % Move focus off of any edit text so the changes can be seen.
        uicontrol(handles.saveButton);
        
        saveNewGroup(hObject, eventdata, handles);
    elseif strcmp(eventdata.Key, 'escape')
        cancelNewGroup(hObject, eventdata, handles);
    end
end


function pickOutputPath(~, ~, handles)
    pickedDir = uigetdir();
    
    if pickedDir ~= 0
        set(handles.outputPathEdit, 'String', pickedDir)
    end
end


function createNewSource(~, ~, handles)
    [label, ~] = newSource();
    if ~isempty(label)
        updateSourcesPopup(handles, label);
    end
end


function cancelNewGroup(~, ~, ~)
    uiresume
end


function saveNewGroup(~, ~, handles)
    % TODO: validate inputs
    handles.outputPath = get(handles.outputPathEdit, 'String');
    handles.label = get(handles.labelEdit, 'String');
    sourceLabels = get(handles.sourcePopup, 'String');
    handles.source = sourceLabels{get(handles.sourcePopup, 'Value')};
    guidata(handles.figure, handles);
    
    % Remember these parameters for the next time the protocol is used.
    %setpref('ProtocolDefaults', class(handles.pluginInstance), handles.pluginInstance.parameters());
    
    uiresume
end
