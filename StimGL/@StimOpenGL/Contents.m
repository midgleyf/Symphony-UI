% SYNOPSIS
%
% The @StimOpenGL class is a Matlab object with methods to access the
% 'StimulateOpenGL II' program via the network.  Typically,
% 'StimulateOpenGL II' is run on the local machine, in which case all
% communication is via a network loopback socket.  However, true remote
% control of the StimulateOpenGL II program is supported.
%
% This class provides nearly total control over a running StimulateOpenGL
% II process -- from starting and stopping plugins, to setting experiment
% data, to dumping frames by framenumber.  All possible functions available
% in the UI of StimulateOpenGL II (and some not in the UI, such as dumping
% frames) are accessible via matlab method calls on @StimOpenGL objects.
%
% Instances of @StimOpenGL are not very stateful.  Just about the only real
% state they maintain internally is a variable that is a handle to a
% network socket.  
%
% The network socket handle is used with the 'CalinsNetMex' mexFunction, 
% which is a helper mexFunction that does all the actual socket 
% communications for this class (since Matlab lacks native network
% support).
%
% Users of this class merely need to construct an instance of a @StimOpenGL
% object and all network communication with the StimulateOpenGL II process
% is handled transparently.
%
% EXAMPLES
%
% my_s = StimOpenGL;  % connects to StimulateOpenGL II program running on
%                     % local machine
%
% stats = GetStats(my_s); % retrieves some stats from the program
%
%
% SetParams(my_s, 'MovingObjects', struct('quad_fps', 'true', 'objLen', '20'));
%
% Start(my_s, 'MovingObjects'); % starts the MovingObjects plugin
%
% image = DumpFrame(my_s, 100); % dump frame 100 of the currently-running
%                               % plugin (in this case, moving obects)
%
% Stop(my_s, 1); % tell program to stop running plugin, saving data
%
%
%
% FUNCTION REFERENCE
%
%    myobj = StimOpenGL()
%    myobj = StimOpenGL(host)
%    myobj = StimOpenGL(host, port)
%
%                Constructor.  Constructs a new instance of a @StimOpenGL 
%                object and immediately attempts to connect to the 
%                running process via the network. The default constructor
%                (no arguments) attempts to connect to 'localhost' port
%                4141.  Additional versions of this constructor support
%                specifying a host and port.
%
%    plugs = ListPlugins(myobj)
%        
%                List plugins command.  Lists all the plugins that are
%                loaded in memory.  All plugins in this list can receive
%                'Start', 'Stop', 'GetParams' and 'SetParams' commands.
%                The returned data is a cell array of strings.
%
%    myobj = Start(myobj, 'PluginName')
%    myobj = Start(myobj, 'PluginName', start_unpaused_flag)
%
%                Start a plugin by name.  The string 'PluginName' must be a 
%                valid plugin as exists in the list obainted from the 
%                ListPlugins command.   Plugins typically also take a set
%                of parameters.  The parameters the plugin uses are the
%                ones extant at the time of this call, having been
%                optionally previously specified with the SetParams command
%                (see SetParams.m).  By default plugins start in a 'paused'
%                state but they may be told to start unpaused, in which
%                case the 3-argument version of this function may be used,
%                setting start_unpaused_flag to true (1).
%
%    myobj = Stop(myobj)
%    myobj = Stop(myobj, save_data_flag)
%   
%                Stop the currently running pluing (if any).  See Running.m
%                to determine which (if any) plugin is running.  Plugins
%                are silently unloaded immediately and no data is saved by
%                default.  However, the second version of this function,
%                taking the 'save_data_flag' specifies that plugin data
%                should be saved (if the flag is true).  Data is saved in 
%                the program 'SaveDir'.  The 'SaveDir' can be modified
%                using the SetSaveDir call.  It can be queried using the
%                GetSaveDir call.
%
%    plugname = Running(myobj)
%
%                Determing which plugin, if any, is currently active and
%                running.  An active plugin is one for which 'Start' was
%                called but 'Stop' has not yet been called, or which has
%                not terminated on its own (plugins may terminate on their
%                own at any time, but at the time of this writing no
%                existing plugin does so).  Returns the plugin name that is
%                running as a string, or the empty string if no plugins are
%                running.
%
%    boolval = IsPaused(myobj)
%
%                Determine if the program is currently in the 'paused' or
%                'unpaused' state.  Returns true if the program is paused,
%                or false otherwise.  The program's paused state
%                may be modified with the Pause and Unpause calls.
%
%    boolval = IsInitialized(myobj)
%
%                Determine if the running plugin (if any) is currently in 
%                the 'initialized' or 'uninitialized' state.  Returns a
%                true value if the plugin has finished initializing. When a
%                plugin is first started, it remains in the uninitialized
%                state until initialization finishes (usually under 1
%                second after it is started). 
%
%    myobj = Pause(myobj)
%
%                Pause the StimulateOpenGL II program.  Pausing only really
%                makes sense when a plugin is currently running (see
%                Running.m).  Paused plugins do not generate new frames on
%                the screen and the GL window for the plugins typically 
%                will be frozen on the last frame drawn before the pause
%                took place.   The pause command silently fails if there is
%                no running plugin.
%
%    myobj = Unpause(myobj)
%
%                The opposite of pause -- resumes execution of the
%                currently-running plugin. Pausing/unpausing only makes
%                sense if there *is* a currently-running plugin.  Unpaused
%                plugins continue to drawn new frames as normal, as if they
%                were never paused.
%
%
%    stats = GetStats(myobj)
%                
%                Get stats command.  Retrieves a collection of various 
%                statistics and other general information. Note that some 
%                of the information returned here is obtainable via 
%                separate calls as well (the time via GetTime, program 
%                version via GetVersion, window dimensions via GetHeight 
%                and GetWidth, etc).  The returned data is a struct.
%
%    params = GetParams(myobj, 'PluginName')
%
%                Retrieve the configuration parameters (if any) for a
%                particular plugin.  Configuration parameters are a struct
%                of name/value pairs that plugins use to affect their
%                runtime operation. The returned structure may be empty if
%                no parameters have been set, or it may contain name/value
%                pairs corresponding to the configuration parameters of the
%                plugin in question. Note that each plugin maintains its
%                own set of configuration parameters, hence the need to
%                call GetParams specifying which plugin you are interested
%                in.
%
%    myobj = SetParams(myobj, 'PluginName', params_struct)
%
%                Set the configuration parameters for a particular plugin.
%                Configuration parameters are a struct of name/value pairs
%                that plugins use to affect their runtime operation.  The
%                structure specified here will completely replace the
%                existing struct (if any) that the plugin was using for its
%                configuration parameters.  Note that each plugin maintains
%                its own set of configuration parameters, hence the need to
%                call SetParams specifying the plugin name.  This call
%                cannot be made while the plugin in question is running,
%                because at that point the plugin may be actively using its
%                parameters and replacing them while it is running is not
%                defined.  Therefore, plugin parameters (if any) should be
%                set before the desired plugin is to be started.
%
%    cell_array_of_strings = GetFrameVarNames(myobj)
%                
%                Retrieves the names of the frame vars.  Returns an Mx1 cell array
%                of strings.  Each string represents the name of a frame
%                var field as returned from GetFrameVars.  
%                See GetFrameVars.m to retrieve the frame vars themselves.
%
%    stats = GetFrameVars(myobj)
%                
%                Get frame vars command.  Returns an MxN array of doubles
%                which are the frame vars for the last plugin that ran
%                successfully.  Each row represents one frame (or 1 of 3
%                grayplanes in quad-frame mode).  The frame var columns of
%                the row can be identified by looking at the results
%                returns from the GetFrameVarNames.m method.  As of the
%                time of this writing, only two plugins support frame vars:
%                MovingObject and MovingGrating.
%
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
%     imgdata = DumpFrames(myobj, frameNumber, count)
%     imgdata = DumpFrames(myobj, frameNumber, count, cropRect, downsample_pix)
%
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
%                Optimal use of this function would be to call DumpFrames
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
%
%    res = DumpFrameToFile(myobj, frameNumber, 'filename_to_save.bmp')
%              
%                Very similar to the DumpFrame.m function, however this
%                function simply saves image data to a file rather than
%                returning it to a matlab variable.  The file saved is of
%                the windows BMP format.  Performance-wise, the same
%                caveats that apply to DumpFrame apply to this function
%                (namely, sequential frame reads are the fastest, with big
%                jumps or backwards jumps being slow). Returns true on
%                success or 0 on failure. 
%      
%    frameCount = GetFrameCount(myobj)
%
%                Returns the frame number of the current frame of the
%                currently running plugin. Calling this function without a
%                plugin currently running is unspecified, and will throw an
%                error.  
%
%    hwFrameCount = GetHWFrameCount(myobj)
%
%                Returns the number of frames that the video board has
%                drawn to the screen since some unspecified time in the
%                past.  The number returned is monotonically increasing and
%                does not require a currently running plugin.  It is
%                a count of the number of vblanks that the video board
%                has experienced since bootup.  However, on windows this
%                function is not supported natively and the obtained
%                framecount is unreliable at best.  Do not use on Windows.  
%                Repeat: 
%
%                DO NOT USE THIS FUNCTION FOR 'StimulateOpenGL II'
%                PROCESSES RUNNING ON WINDOWS!
%
%    rate = GetRefreshRate(myobj)
%
%                Returns the refresh rate in Hz of the monitor that the
%                Open GL window is currently mostly sitting in.  Note that
%                moving the window to different monitors will cause this
%                function to return updated values, so the returned value
%                is accurate and reliable and is the rate the plugin should
%                be using as it runs.
%
%    height = GetCurrentRSeed(myobj)
%
%                Returns the current random number generator seed used by 
%                the plugin.  Useful for rndtrial=1 with MovingObjects
%
%    width = GetWidth(myobj)
%
%                Returns the width of the Open GL window in pixels.
%
%    height = GetHeight(myobj)
%
%                Returns the height of the Open GL window in pixels.
%
%    time = GetTime(myobj)
%
%                Returns the number of seconds since StimulateOpenGL II was
%                started.  The returned value has a resolution in the
%                nanoseconds range, since it comes from the CPU's timestamp
%                counter.
%
%    version = GetVersion(myobj)
%
%                Obtain the version string associated with the
%                SimulateOpenGL II process we are connected to.
%
%    dir = GetSaveDir(myobj)
%
%                Obtain the directory path to which data files will be
%                saved.  Data files are saved by plugins when they are
%                Stopped with the save_data_flag set to true.
%
%    myobj = SetSaveDir(myobj, dir)
%
%                Specify directory path to which data files will be
%                saved.  Data files are saved by plugins when they are
%                Stopped with the save_data_flag set to true.  This setting
%                is persistent across runs of the program.
%
%    boolval = IsConsoleHidden(myobj)
%
%                Determine if the console window is currently hidden or 
%                visible.  Returns true if the console window is hidden,
%                or false otherwise.  The console window may be
%                hidden/shown using the ConsoleHide() and ConsoleUnhide()
%                calls.
%
%    myobj = ConsoleHide(myobj)
%
%                Hides the StimulateOpenGL II console window.  This may be
%                useful in order to unclutter the desktop or as a
%                performance optimization, since the console window may
%                theoretically interfere with the GL window's framerate.
%
%    myobj = ConsoleUnhide(myobj)
%
%                Unhides the StimulateOpenGL II console window, causing it
%                to be shown again.  See also ConsoleHide and
%                IsConsoleHidden.
%
%    myobj = Close(myobj)
%
%                Closes the network connection to the StimulateOpenGL II
%                process. Useful only to cleanup resources when you are
%                done with a connection to StimulateOpenGL II.
%
%    myobj = SetVSyncDisabled(myobj, disabled_flag)
%
%                Disables/enables VSync.  See also IsVSyncDisabled.m call.
%                This setting is persistent across runs of the program.
%
%    boolval = IsVSyncDisabled(myobj)
%
%                Determine if the program frame renderer has VSync 
%                disabled or enabled (default returns false, or enabled). 
%                The program's VSync may be disabled with the
%                SetVSyncDisabled call.  

