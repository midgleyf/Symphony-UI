%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

%    imgdata = DumpFrames(myobj, frameNumber, count)
%    imgdata = DumpFrames(myobj, frameNumber, count, cropRect, downsample_pix)
%                Retrieve count frames starting at 'frameNumber' from the currently
%                running plugin.  The returned matrix is a matrix of
%                unsigned chars with dimensions: 3 x width x height x count (width
%                and height are obtained from GetHeight and GetWidth method
%                calls).  Note that if frameNumber is in the past (that is,
%                lower than the current frameCount [see GetFrameCount]),
%                then the plugin may have to be restarted internally and
%                fast-forwarded to the specified frameNumber (a slow
%                operation).  Also note that if 'frameNumber' is some
%                number far in the future (much larger than frameCount) the
%                plugin will have to compute all the frames in between the
%                current frame and frameNumber (a slow operation).  By far
%                the slowest possible way to read frames is in reverse or
%                randomly, so avoid that usage pattern, if possible!
%                Optimal use of this function would be to call DumpFrame
%                specifying sequential frameNumbers, eg: DumpFrames(myObj,
%                100,5), DumpFrame(myObj, 105,4), DumpFrame(myObj, 109,7), etc.
%
%                The second form of the function allows you to specify a
%                crop rectangle for a sub-rectangle of the frame's window
%                as [ origin_x origin_y width height ] with origin 0,0
%                being at the bottom-left of the window.
%
%                The downsample_pix parameter allows you to downsample the
%                returned pixels by every [k l]'th pixel in the X and Y
%                directions, respectively.
function [imgdat] = DumpFrames(s, frameNum, count, varargin)
    crop = [0 0 0 0];
    ds = [1 1];
    if (nargin < 3),
        error('Please pass 3 or more arguments to DumpFrames');
        return;
    end;
    if (nargin >= 4),
        crop = varargin{1};
        if (~isnumeric(crop) | size(crop) ~= [1 4]),
            error('cropRect parameter needs to be a 4-vector of positive integers!');
        end;
    end;
    if (nargin >= 5),
        ds = varargin{2};
        if (~isnumeric(ds) | size(ds) ~= [1 2]),
            error('downsample_pix parameter need to be a 2-vector of positive integers!');
        end;
    end;
    if (count > 240), 
        warning('More than 240 frames per DumpFrames call is not officially supported and may lead to low memory conditions!');
    end;
    plug=Running(s);
    if (isempty(plug)),
        imgdat = [];
        error('Cannot call DumpFrame when a plugin isn''t running!  Call Start() first!');
        return;
    end;
    if (~isnumeric(frameNum) | frameNum < 0),
        error('Frame number parameter needs to be a positive integer!');
    end;

    if (~IsPaused(s)),
        warning('Plugin was not paused -- pausing plugin in order to complete DumpFrame command...');
        Pause(s);
    end;
    pluginFrameNum = GetFrameCount(s);
    if (~isnumeric(count) | count <= 0),
        warning('Count specified is invalid, defaulting to 1');
        count = 1;
    end;
    if (frameNum <= pluginFrameNum),
        warning(sprintf('Frame count specified %d is <= the plugin''s current frame number of %d, restarting plugin (this is slow!!)',frameNum, pluginFrameNum));
        Stop(s);
        Start(s, plug);
    end;
    if (ds(1) <= 0) ds(1) = 1; end;
    if (ds(2) <= 0) ds(2) = 1; end;        
    ChkConn(s);
    w = GetWidth(s);
    h = GetHeight(s);
    if (crop(1) > w), crop(1) = w; end;
    if (crop(2) > h), crop(2) = h; end;
    if (crop(3) > 0 & (crop(3)+crop(1) < w)), 
        w = crop(3); 
    else
        w = w-crop(1);
    end;
    if (crop(4) > 0 & (crop(4)+crop(2) < h)), 
        h = crop(4);     
    else
        h = h-crop(2);
    end;
    CalinsNetMex('sendString', s.handle, sprintf('getframe %d %d %d %d %d %d %d %d UNSIGNED BYTE\n', frameNum, count, crop(1),crop(2),crop(3),crop(4), ds(1),ds(2)));
    line = CalinsNetMex('readLine', s.handle);
    nbytes = sscanf(line,'BINARY DATA %f');
    if (~isnumeric(nbytes)),
        error('Expected BINARY DATA line, didn''t get it');
    end;
    wp = floor(w / ds(1));
    hp = floor(h / ds(2));
    expected = 3 * wp * hp * count;
    if (nbytes ~= expected),
        error(sprintf('Expected BINARY DATA of size %d bytes, instead got %d!',expected,nbytes));
    end;
    imgdat=CalinsNetMex('readMatrix', s.handle, 'uint8', [3 wp hp count]);
    ReceiveOK(s);

    