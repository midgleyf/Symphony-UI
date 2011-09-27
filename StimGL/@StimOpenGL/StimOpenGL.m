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
function [s] = StimOpenGL(varargin) 
    host = 'localhost';
    port = 4141;
    if (nargin >= 1), host = varargin{1}; end;
    if (nargin >= 2), port = varargin{2}; end;
    if (~ischar(host) | ~isnumeric(port)),
        error('Host must be a string and port must be a number');
    end;
    if (strcmp(host, 'localhost'))
        if ismac
            OSFuncs('ensureProgramIsRunning', 'StimulateOpenGL_II.app/Contents/MacOS/StimulateOpenGL_II');
        else
            OSFuncs('ensureProgramIsRunning', 'StimulateOpenGL_II');
        end
    end;
    s=struct;
    s.host = host;
    s.port = port;
    s.in_chkconn = 0;
    s.handle = CalinsNetMex('create', host, port);
    s.ver = '';
    s = class(s, 'StimOpenGL');
    CalinsNetMex('connect', s.handle);
    ChkConn(s);
    s.ver = DoQueryCmd(s, 'GETVERSION');
    

