function dims = centerWindowOnScreen(width, height, screen)
    % Returns the left, bottom, width and height to use to center a window of the given size on the indicated or main screen.
    
    if nargin < 3
        screen = 1;
    end
    
    dpi = get(0, 'ScreenPixelsPerInch');
    sz = int16(screenBounds(screen) / dpi * 72);
    sz1 = int16(screenBounds('primary') / dpi * 72);
    
    x = sz(1) + sz(3) / 2 - width / 2;
    if ismac
        y = sz(2) + sz(4) / 2 - height / 2;
    else
        y = sz1(2) + sz1(4) - (sz(2) + sz(4) / 2 + height / 2);
    end
    
    dims = int16([x y width height]);
end
