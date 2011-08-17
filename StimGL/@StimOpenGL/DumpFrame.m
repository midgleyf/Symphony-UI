%    imgdata = DumpFrame(myobj, frameNumber)
%    imgdata = DumpFrame(myobj, frameNumber, cropRect, downsample_pix)
%
%                Retrieve frame number 'frameNumber' from the currently
%                running plugin.  The returned matrix is a matrix of
%                unsigned chars with dimensions: 3 x width x height (width
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
%                specifying sequential frameNumbers, eg: DumpFrame(myObj,
%                100), DumpFrame(myObj, 101), DumpFrame(myObj, 102), etc.  
% 
%                The second form of the function allows you to specify a
%                crop rectangle for a sub-rectangle of the frame's window
%                as [ origin_x origin_y width height ] with origin 0,0
%                being at the bottom-left of the window.
% 
%                The downsample_pix parameter allows you to downsample the
%                returned pixels by every [k l]'th pixel in the X and Y
%                directions, respectively.
%
function [imgdat] = DumpFrame(s, frameNum, varargin)
      if (~length(varargin)),
        imgdat = DumpFrames(s, frameNum, 1);
      elseif (length(varargin) == 2),
        imgdat = DumpFrames(s, frameNum, 1, varargin{1}, varargin{2});
      else
        error('DumpFrame must take exactly 2 or 4 parameters');
      end;
         
          
%     plug=Running(s);
%     if (isempty(plug)),
%         imgdat = [];
%         error('Cannot call DumpFrame when a plugin isn''t running!  Call Start() first!');
%         return;
%     end;
%     if (~isnumeric(frameNum) || frameNum < 0),
%         error('Frame number parameter needs to be a positive integer!');
%     end;
%    
%     if (~IsPaused(s)),
%         warning('Plugin was not paused -- pausing plugin in order to complete DumpFrame command...');
%         Pause(s);
%     end;
%     pluginFrameNum = GetFrameCount(s);
%     if (frameNum <= pluginFrameNum),
%         warning(sprintf('Frame count specified %d is <= the plugin''s current frame number of %d, restarting plugin (this is slow!!)',frameNum, pluginFrameNum));
%         Stop(s);
%         Start(s, plug);
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
%     ReceiveOK(s);

    