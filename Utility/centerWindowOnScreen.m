function dims = centerWindowOnScreen(width, height, screen)
    % Returns the left, bottom, width and height to use to center a window of the given size on the main screen.
    
    if nargin < 3
        screen = 1;
    end
    
    dpi = get(0, 'ScreenPixelsPerInch');
    
    if ismac
        prevUnits = get(0, 'Units');
        set(0, 'Units', 'pixels');
        mps = get(0, 'MonitorPositions');
        set(0, 'Units', prevUnits);
    else
        mps = zeros(System.Windows.Forms.Screen.AllScreens.Length, 4);
        for i = 1:System.Windows.Forms.Screen.AllScreens.Length
            bounds = System.Windows.Forms.Screen.AllScreens(i).Bounds;
            mps(i, 1) = bounds.X + 1;
            mps(i, 2) = bounds.Y + 1;
            mps(i, 3) = bounds.Width;
            mps(i, 4) = bounds.Height;
        end
    end
    mps = mps / dpi * 72;
    
    if screen > size(mps, 1)
        error('Symphony:ScreenIndexTooHigh', ['There are only ' num2str(size(mps, 1)) ' screens available.']);
    end
    
    sz = mps(screen, :);
    x = sz(1) + sz(3) / 2 - width / 2;
    if ismac
        y = height + sz(4) / 2 - height / 2;
    else
        y = (mps(1,2) + mps(1,4) - (sz(2) + sz(4))) + sz(4) / 2 - height / 2;
    end
    dims = uint16([x y width height]);
end
