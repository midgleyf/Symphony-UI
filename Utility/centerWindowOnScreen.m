function dims = centerWindowOnScreen(width, height)
    dpi = get(0, 'ScreenPixelsPerInch');
    sz = get(0, 'ScreenSize') / dpi * 72;
    x = sz(1) + sz(3) / 2 - width / 2;
    y = sz(2) + sz(4) / 2 + height / 2;
    dims = uint16([x y width height]);
end
