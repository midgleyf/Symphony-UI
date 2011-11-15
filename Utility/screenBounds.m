function b = screenBounds(screenNum)
    if ismac
        prevScreenUnits = get(0, 'Units');
        set(0, 'Units', 'pixels');
        b = get(0, 'MonitorPositions');
        set(0, 'Units', prevScreenUnits);
        primary = 1;
    else
        b = zeros(System.Windows.Forms.Screen.AllScreens.Length, 4);
        for i = 1:System.Windows.Forms.Screen.AllScreens.Length
            screen = System.Windows.Forms.Screen.AllScreens(i);
            b(i, 1) = screen.Bounds.X + 1;
            b(i, 2) = screen.Bounds.Y + 1;
            b(i, 3) = screen.Bounds.Width;
            b(i, 4) = screen.Bounds.Height;
            if screen.Primary
                primary = i;
            end
        end
    end
    
    if nargin == 1
        if isnumeric(screenNum)
            if screenNum > size(b, 1)
                error('Symphony:ScreenIndexTooHigh', ['There are only ' num2str(size(b, 1)) ' screens available.']);
            end
        elseif ischar(screenNum) && strcmp(screenNum, 'primary')
            screenNum = primary;
        end
        
        b = b(screenNum, :);
    end
end
