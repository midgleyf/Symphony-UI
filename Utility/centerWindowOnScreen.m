function dims = centerWindowOnScreen(width, height)
    % Returns the left, bottom, width and height to use to center a window of the given size on the main screen.
    
    dpi = get(0, 'ScreenPixelsPerInch');
    
    prevUnits = get(0, 'Units');
    set(0, 'Units', 'pixels');
    sz = get(0, 'MonitorPositions');
    %sz = sz(1, :) / dpi * 72;
    x = sz(1) + sz(3) / 2 - width / 2;
    y = sz(2) + sz(4) / 2 - height / 2;
    dims = uint16([x y width height]);
    set(0, 'Units', prevUnits);
end
