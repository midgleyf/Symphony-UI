function s = windowScreen(fh)
    % Returns the index of the screen on which most of the figure window lies.
    
    % Get the figure position in pixels.
    prevFigureUnits = get(fh, 'Units');
    set(fh, 'Units', 'pixels');
    figPos = get(fh, 'Position');
    set(fh, 'Units', prevFigureUnits);
    
    mps = screenBounds();
    p = screenBounds('primary');
    
    % Convert figure coordinates (origin at lower-left) to screen coordinates (origin at upper-left).
    figPos(2) = p(4) - (figPos(2) + figPos(4));
    
    % Calculate the intersection of the figure with each screen.
    s = [];
    maxCov = 0;
    for i = 1:size(mps, 1)
        if figPos(1) < mps(i, 1) + mps(i, 3) && ...
           figPos(1) + figPos(3) > mps(i, 1) && ...
           figPos(2) < mps(i, 2) + mps(i, 4) && ...
           figPos(2) + figPos(4) > mps(i, 2)
            cov = (min(figPos(1) + figPos(3), mps(i, 1) + mps(i, 3)) - max(figPos(1), mps(i, 1))) * ...
                  (min(figPos(2) + figPos(4), mps(i, 2) + mps(i, 4)) - max(figPos(2), mps(i, 2)));
            if cov > maxCov
                s = i;
                maxCov = cov;
            end
        end
    end
end
