classdef sonyalpha < handle
  % SONYALPHA A class to control a Sony Alpha Camera (NEX, Alpha, ...) compatible
  % with the Camera Remote API by Sony.
  %
  % Usage
  % -----
  %
  % >> camera = sonyalpha;
  % >> image(camera);
  %
  % Then you can use the Methods:
  %   getstatus(camera):  get the camera status
  %   start:              set the camera ready for shooting pictures
  %   stop:               stop the shooting mode
  %
  %   iso:                set/get ISO setting
  %   shutter:            set/get shutter speed setting
  %   mode:               set/get the PASM mode
  %   timer:              set/get the self timer
  %   fnumber:            set/get the F/D aperture
  %   white:              set/get the white balance
  %
  %   urlread:            take a picture and return the distant URL (no download)
  %   imread:             take a picture and download the RGB image (no display)
  %   image:              take a picture and display it
  %
  % Connecting the Camera
  % ---------------------
  % 
  % Start your camera and use its Remote Control App (e.g. Play Memories App) 
  % from the Camera settings. This starts the JSON REST HTTP server, used to 
  % control the camera. The Network SSID is shown on the Camera screen.
  % Connect from your PC on that network.
  % The usual associated IP is then 192.168.122.1 (port 8080)
  %
  % The connection must be a dedicated ad-hoc, e.g. can NOT use an intermediate 
  % router. If you are already connected to the Internet, you have to drop your
  % current connection, or use an additional Wifi adapter (e.g. USB-Wifi).
  %
  % Requirements/Installation
  % -------------------------
  %
  %  - Matlab, no external toolbox
  %  - A wifi connection
  %  - A Sony Camera
  %  - curl
  %  - ffmpeg (for liveview)
  %
  %  Just copy the files and go into the directory. Then type commands above, once the
  %  camera is configured (see above).

  % Credits
  % -------
  % https://github.com/micolous/gst-plugins-sonyalpha
  % https://github.com/Bloodevil/sony_camera_api
  % https://developer.sony.com/develop/cameras/#overview-content
  %
  % (c) E. Farhi, GPL2, 2018.

  properties
    url           = 'http://192.168.122.1:8080/sony/camera';
    
    % settings, updated on getstatus
    exposureMode  = '';
    cameraStatus  = '';
    selfTimer     = '';
    zoomPosition  = '';
    shootMode     = '';
    exposureCompensation = ''; % in EV
    fNumber       = '';
    focusMode     = '';
    isoSpeedRate  = '';
    shutterSpeed  = '';
    whiteBalance  = '';
    
    status        = '';
    version       = '';
    updateTimer   = '';
    
    % continuous/timelapse modes
    continuous_mode = 0;
    timelapse_mode  = 0;
    timelapse_clock = 0;
    timelapse_interval = 0;

  end % properties
  
  methods
    function self = sonyalpha(url)
      % sonyalpha: initialize the remote control for Sony Alpha Camera
      if nargin > 1
        self.url = url;
      end
      
      self.version = self.get('getApplicationInfo');
      
      % init timer for regular updates, timelapse, etc
      self.updateTimer  = timer('TimerFcn', @TimerCallback, ...
          'Period', 5.0, 'ExecutionMode', 'fixedDelay', 'UserData', self, ...
          'Name', mfilename);

      self.start;
      disp([ mfilename ': [' datestr(now) '] Welcome to Sony Alpha ' char(self.version) ' at ' self.url ])

    end % sonyalpha
    
    % INFO stuff
    function status = getstatus(self)
      % getstatus: get the Camera status and all settings
      json = '{"method": "getEvent", "params": [false], "id": 1, "version": "1.2"}';
      [ret, message] = curl(self.url, json);
      message = loadjson(message);
      message = message.result;
      status  = struct();
      status.unsorted ={};
      for index=1:numel(message)
        this = message{index};
        if isempty(this), continue; end
        if isfield(this, 'type') && isfield(this, this.type)
          status.(this.type) = this.(this.type);
          if iscell(status.(this.type)) && numel(status.(this.type)) == 1
            status.(this.type) = status.(this.type){1};
          end
        elseif isfield(this, 'type')
          status.(this.type) = this;
        else
          if iscell(this) && numel(this) == 1
            this = this{1};
          end
          status.unsorted{end+1} = this;
        end
      end
      
      % store that information into properties
      self.status       = status;
      try
        self.exposureMode = status.exposureMode.currentExposureMode;
        self.cameraStatus = status.cameraStatus;
        self.selfTimer    = status.selfTimer.currentSelfTimer;
        self.zoomPosition = status.zoomInformation.zoomPosition;
        self.shootMode    = status.shootMode.currentShootMode;
        self.exposureCompensation = status.exposureCompensation.currentExposureCompensation/3;
        self.fNumber      = status.fNumber.currentFNumber;
        self.focusMode    = status.focusMode.currentFocusMode;
        self.isoSpeedRate = status.isoSpeedRate.currentIsoSpeedRate;
        self.shutterSpeed = status.shutterSpeed.currentShutterSpeed;
        self.whiteBalance = status.whiteBalance.currentWhiteBalanceMode;
      end
    end % getstatus
    
    % generic get for most API commands ------------------------------------
    function ret = get(self, method)
      % get('method'):  get the given API method call (no argument)
      json = [ '{"method": "' method '","params": [],"id": 1,"version": "1.0"}' ];
      ret  = curl(self.url, json);
    end % get
    
    function ret = set(self, method, value)
      % set('method', param): get the given API method call (with argument)
      if isnumeric(value),  value = num2str(value);
      elseif ischar(value), value = [ '"' value '"' ];
      elseif islogical(value)
        if value, value = 'true'; else value = 'false'; end
      end
      json = [ '{"method": "' method '","params": [' value '],"id": 1,"version": "1.0"}' ];
      ret  = curl(self.url, json);
    end % set
    
    % Camera Shooting ----------------------------------------------------------
    function ret = start(self)
      % start: set the camera into shooting mode
      ret = self.get('startRecMode');
      self.getstatus;
      start(self.updateTimer);
    end % start
    
    function ret = stop(self)
      % stop: stop the camera shooting mode
      ret = self.get('stopRecMode');
      self.continuous_mode = false;
      self.timelapse_mode  = false;
    end % stop
    
    function url = urlread(self)
      % urlread: take a picture and return the distant URL (no upload)
      % must have used 'start' before (e.g. at init).
      url = char(self.get('actTakePicture'));
    end % urlread
    
    function im = urlwrite(self, filename)
      % urlread: take a picture, and download it as a local file
      % must have used 'start' before (e.g. at init).
      
      if nargin < 2, filename = ''; end
      
      % get the URL and its extension
      url = self.urlread;
      [p, f, ext] = fileparts(url);
        
      if isempty(filename)
        filename = [ f e ]; % saves locally using the distant image name
      else
        % check extension
        [p,f,E] = fileparts(filename);
        if isempty(E), filename = [ filename ext ]; end
      end
      % then get URL and display it
      im   = urlwrite(url, filename);
    end % urlwrite
    
    function [im, exif] = imread(self)
      % imread: take a picture, and read it as an RGB matrix.
      %
      % [im, exif] = imread(s)
      %   returns the EXIF data.
      filename = tempname;
      url  = self.urlwrite(filename);
      
      im   = imread(url); % local file
      if nargout > 1, exif = imfinfo(file); end
      delete(filename);
     
    end % imread
    
    function h = image(self)
      h = image(self.imread);
    end % image
    
    % Camera settings ----------------------------------------------------------
    function ret = iso(self, value)
      % iso(s):        get the ISO setting as a string (can be 'AUTO')
      % iso(s, 'iso'): set the ISO setting as a string (can be 'AUTO')
      % iso(s, 'supported') return supported ISO settings (strings)
      %
      % The ISO value can be e.g. AUTO 100 200 400 800 1600 3200 6400 12800 25600 
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = get(self, 'getIsoSpeedRate');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = get(self, 'getSupportedIsoSpeedRate');
      else
        ret = self.set('setIsoSpeedRate', num2str(value));
      end
    end % iso
    
    function ret = mode(self, value)
      % mode(s):         get the shooting Mode (e.g. PASM)
      % mode(s, 'PASM'): set the shooting Mode (e.g. PASM) as a string
      % mode(s, 'supported') return supported shooting Modes (strings)
      %
      % The shooting Mode can be 'Program Auto', 'Aperture', 'Shutter', 'Manual'
      %   'Intelligent Auto', or 'P', 'A', 'S', 'M'
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = get(self, 'getExposureMode');
        switch ret
        case 'Program Auto'; ret = 'P';
        case 'Aperture';     ret = 'A';
        case 'Shutter';      ret = 'S';
        case 'Manual';       ret = 'M';
        end
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = get(self, 'getSupportedExposureMode');
      else
        switch upper(value(1))
        case 'P'; value = 'Program Auto';
        case 'A'; value = 'Aperture';
        case 'S'; value = 'Shutter';
        case 'M'; value = 'Manual';
        end
        ret = self.set('setExposureMode', value);
      end
    end % mode
    
    function ret = timer(self, value)
      % timer(s):      get the self Timer setting
      % timer(s, val): set the self Timer setting in seconds
      % timer(s, 'supported') return supported self Timer settings (numeric)
      %
      % The self Timer value can be e.g. 0, 2 or 10 (numeric)
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = get(self, 'getSelfTimer');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = get(self, 'getSupportedSelfTimer');
      else
        ret = self.set('setSelfTimer', num2str(value));
      end
    end % timer
    
    function ret = shutter(self, value)
      % shutter(s):      get the shutter speed setting (S mode)
      % shutter(s, val): set the shutter speed setting (S mode) as a string
      % shutter(s, 'supported') return supported shutter speed settings (strings)
      %
      % The shutter speed value can be e.g. '30"', '1"', '1/2', '1/30', '1/250' (string)
      %   where the " symbol stands for seconds.
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = get(self, 'getShutterSpeed');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = get(self, 'getSupportedShutterSpeed');
      else
        ret = self.set('setShutterSpeed', num2str(value));
      end
    end % shutter
    
    function ret = fnumber(self, value)
      % fnumber(s):      get the F/D number (apperture) setting (A mode)
      % fnumber(s, val): set the F/D number (apperture) setting (A mode) as a string
      % fnumber(s, 'supported') return supported F/D numbers (strings)
      %
      % The F/D number value can be e.g. '1.4','2.0','2.8','4.0','5.6'
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = get(self, 'getFNumber');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = get(self, 'getSupportedFNumber');
      else
        ret = self.set('setFNumber', num2str(value));
      end
    end % fnumber
    
    function ret = white(self, value)
      % white(s):      get the white balance setting
      % white(s, val): set the white balance setting
      % white(s, 'supported') return supported white balance modes (strings)
      %
      % The white balance can be a string such as 
      %  'Auto WB'
      %  'Daylight'
      %  'Shade' 
      %  'Cloudy' 
      %  'Incandescent' 
      %  'Fluorescent: Warm White (-1)' 
      %  'Fluorescent: Cool White (0)'
      %  'Fluorescent: Day White (+1)'
      %  'Fluorescent: Daylight (+2)'
      %  'Flash'
      % or a Temperature (numeric for 'Color Temperature' mode) in 2500-9900 K
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = get(self, 'getWhiteBalance');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = get(self, 'getSupportedWhiteBalance');
      else
        if ischar(value)
          json = [ '{"method": "setWhiteBalance","params": ["' value '", false, -1],"id": 1,"version": "1.0"}' ];
          ret = curl(self.url, json);
        elseif isnumeric(value)
          value = round(value/100)*100;
          json = [ '{"method": "setWhiteBalance","params": ["Color Temperature", true, ' num2str(value) '],"id": 1,"version": "1.0"}' ];
          ret = curl(self.url, json);
        end
      end
    end % white
    
    % upper level continuous/timelapse modes
    function continuous(self)
      % timelapse: take a picture continuously
      if self.continuous_mode
        % stop after next capture
        self.continuous_mode = false;
        disp([ mfilename ': stopping continuous shooting' ])
      else
        self.continuous_mode = true;
        disp([ mfilename ': starting continuous shooting' ])
      end
    end % continuous
    
    function timelapse(self, wait)
      % timelapse: take a picture with current settings every 'wait' seconds
      if self.timelapse_mode
        % stop after next capture
        self.timelapse_mode = false;
        disp([ mfilename ': stopping timelapse shooting' ])
      else
        self.timelapse_mode     = true;
        self.timelapse_interval = wait;
        self.timelapse_clock    = clock;
      end
    end
    
    
  end % methods
  
end % sonyalpha class

% internal communication done with curl ----------------------------------------

function message = curl(url, post)
  % prepare curl command
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ;';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
  else           precmd=''; end
  
  cmd = [ 'curl -d ''' post ''' ' url ];
  
  % evaluate command
  [ret, message]=system([ precmd  cmd ]);
  
  if ret % error
    disp(cmd)
    error(message);
  end
  
  % decode JSON output into struct
  message = loadjson(message); % We use JSONlab reader which is more robust

  if isstruct(message) && isfield(message, 'result') && ischar(message.result)
    message.result = strrep(message.result', '\/','/');
  end
  if isstruct(message) && numel(fieldnames(message)) == 2
    if  isfield(message, 'result')
      message = message.result;
    elseif isfield(message, 'error')
      message = message.error;
    end
  end
  if iscell(message) && numel(message) == 1
    message = message{1};
  end
end % curl

function TimerCallback(src, evnt)
  % TimerCallback: update from timer event
  self = get(src, 'UserData');
  if isvalid(self), self.getstatus; 
  else delete(src); return; end
  
  % handle continuous shooting mode
  if strcmpi(self.cameraStatus,'IDLE')
    if self.continuous_mode
      url = self.urlread;
      disp([ mfilename ': [' datestr(now) '] continuous shooting ' url ]);
    elseif self.timelapse_mode && etime(clock, self.timelapse_clock) > self.timelapse_interval
      self.timelapse_clock     = clock;
      url = self.urlread;
      disp([ mfilename ': [' datestr(now) '] timelapse ' url ]);
    end
  
end % TimerCallback

