%    myobj = Pause(myobj)
%
%                Pause the StimulateOpenGL II program.  Pausing only really
%                makes sense when a plugin is currently running (see
%                Running.m).  Paused plugins do not generate new frames on
%                the screen and the GL window for the plugins typically 
%                will be frozen on the last frame drawn before the pause
%                took place.   The pause command silently fails if there is
%                no running plugin.

%  Copyright (c) 2012 Howard Hughes Medical Institute.
%  All rights reserved.
%  Use is subject to Janelia Farm Research Campus Software Copyright 1.1 license terms.
%  http://license.janelia.org/license/jfrc_copyright_1_1.html 

function [s] = Pause(s)

    s = DoSimpleCmd(s, 'PAUSE');
