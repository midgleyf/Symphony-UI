%    res = DumpFrameToFile(myobj, frameNumber, 'filename_to_save.bmp')              
%    res = DumpFrameToFile(myobj, frameNumber, 'filename_to_save.bmp', cropRect, downsample)
%
%                Very similar to the DumpFrame.m function, however this
%                function simply saves image data to a file rather than
%                returning it to a matlab variable.  The file saved is of
%                the windows BMP format.  Performance-wise, the same
%                caveats that apply to DumpFrame apply to this function
%                (namely, sequential frame reads are the fastest, with big
%                jumps or backwards jumps being slow). Returns true on
%                success or 0 on failure. 

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html

function [res] = DumpFrameToFile(s, frameNum, outfile_bmp, varargin)
%     if (~length(Running(s))),
%         res = 0;
%         error('Cannot call DumpFrame when a plugin isn''t running!  Call Start() first!');
%         return;
%     end;
% 
    n = length(varargin);
    if (n > 2),
        error('Incorrect number of arguments to function.');
    end;
        
    if (~ischar(outfile_bmp)),
        error('Output filename needs to be a string');
    end;
    
    crop = [0 0 0 0];
    ds = [1 1];
    if (n >= 1),
        crop = varargin{1};
    end;
    if (n >= 2),
        ds = varargin{2};
    end;
%     if (~isnumeric(frameNum)),
%         error('Frame number parameter needs to be numeric');
%     end;
%    
%     if (~IsPaused(s)),
%         warning('Plugin was not paused -- pausing plugin in order to complete DumpFrame command...');
%         Pause(s);
%     end;
%     ChkConn(s);
%     w=GetWidth(s);
%     h=GetHeight(s);
%     CalinsNetMex('sendString', s.handle, sprintf('getframe %d UNSIGNED BYTE\n', frameNum));
%     line = CalinsNetMex('readLine', s.handle);
%     if (strfind(line, 'BINARY')~=1),
%         error('Expected BINARY DATA line, didn''t get it');
%     end;   
%     imgdat=CalinsNetMex('readMatrix', s.handle, 'uint8', [3 w h]);
    imgdat=DumpFrame(s, frameNum, crop, ds);
    imgdat=BMPMex('convertRGBToBGR', imgdat);
    BMPMex('saveBMP', outfile_bmp, imgdat, size(imgdat,2), size(imgdat, 3) );
    res = 1;
    