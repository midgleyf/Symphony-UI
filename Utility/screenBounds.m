function b = screenBounds(screenNum)
    if ismac
        prevScreenUnits = get(0, 'Units');
        set(0, 'Units', 'pixels');
        b = get(0, 'MonitorPositions');
        set(0, 'Units', prevScreenUnits);
    else
        b = zeros(System.Windows.Forms.Screen.AllScreens.Length, 4);
        for i = 1:System.Windows.Forms.Screen.AllScreens.Length
            screen = System.Windows.Forms.Screen.AllScreens(i).Bounds;
            b(i, 1) = screen.X + 1;
            b(i, 2) = screen.Y + 1;
            b(i, 3) = screen.Width;
            b(i, 4) = screen.Height;
        end
    end
    
    if nargin == 1
        if screenNum > size(b, 1)
            error('Symphony:ScreenIndexTooHigh', ['There are only ' num2str(size(b, 1)) ' screens available.']);
        end
        
        b = b(screenNum, :);
    end
end
