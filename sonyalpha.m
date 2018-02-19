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
  %   iso:                set/get ISO setting
  %   shutter:            set/get shutter speed setting
  %   mode:               set/get the PASM mode
  %   timer:              set/get the self timer
  %   fnumber:            set/get the F/D aperture
  %   white:              set/get the white balance
  %   image:              take a shot and display it
  %   imread:             take a shot and download the image (no display)
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
  %
  % (c) E. Farhi, GPL2, 2018.

  properties
    url           = 'http://192.168.122.1:8080/sony/camera';
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
  end % properties
  
  methods
    function self = sonyalpha(url)
      % sonyalpha: initialize the remote control for Sony Alpha Camera
      if nargin > 1
        self.url = url;
      end

      self.startRecMode;
      self.getstatus;
      
    end % sonyalpha
    
    % INIT and INFO stuff
    function status = getstatus(self)
      % getstatus: get the Camera status and all settings
      json = '{"method": "getEvent", "params": [false], "id": 1, "version": "1.2"}';
      [ret, message] = curl(self.url, json);
      message = loadjson(message);
      message = message.result;
      status = struct();
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
          if iscell(this) && numel(this) == 1
            this = this{1};
          end
          status.(this.type) = this;
        else
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
    end
    
    function ret=getApplicationInfo(self)
      ret = self.get('getApplicationInfo');
    end
    
    function ret=getAvailableApiList(self)
      ret = self.get('getAvailableApiList');
    end
    
    function ret=getVersions(self)
      ret = self.get('getVersions');
    end
    
    % generic get for most API commands ------------------------------------
    function ret=get(self, getAPI)
      % getAPI can be any  Sony API call without argument
      %
      % getApplicationInfo
      % getAvailableApiList
      % getVersions
      %
      % startRecMode
      % actTakePicture
      % getAvailableExposureMode
      % getAvailableFocusMode
      % getAvailableSelfTimer
      % getAvailableExposureCompensation
      % getAvailableFNumber
      % getAvailableShutterSpeed
      % getWhiteBalance
      % getIsoSpeedRate
      % getAvailablePostviewImageSize
      json = [ '{"method": "' getAPI '","params": [],"id": 1,"version": "1.0"}' ];
      ret  = curl(self.url, json);
    end
    
    function ret=set(self, getAPI, value)
      % 'setSelfTimer',    (0, 2 or 10)
      % 'setExposureMode', ('Program Auto','Aperture', 'Shutter', 'Manual', 'Intelligent Auto')
      % 'setFocusMode',    ('AF-S'    'AF-C'    'DMF'    'MF')
      % 'setExposureCompensation', (-9:9) per 1/3 EV
      % 'setFNumber',      (e.g. '3.5')
      % 'setShutterSpeed'  (e.g. '1/15')
      % 'setIsoSpeedRate'  ('AUTO'    '100'    '200'    '400'    '800'    '1600'    '3200'    '6400'    '12800'  '25600')
      % 'setPostviewImageSize' ('Original'    '2M') <- faster image transfer
      if isnumeric(value),  value = num2str(value);
      elseif ischar(value), value = [ '"' value '"' ];
      elseif islogical(value)
        if value, value = 'true'; else value = 'false'; end
      end
      json = [ '{"method": "' getAPI '","params": [' value '],"id": 1,"version": "1.0"}' ];
      ret  = curl(self.url, json);
    end
    
    % Camera Shooting ----------------------------------------------------------
    function ret=startRecMode(self)
      ret = self.get('startRecMode');
    end
    
    function ret=close(self)
      ret=self.get('stopRecMode');
    end
    
    function url=actTakePicture(self)
      url = self.get('actTakePicture');
    end
    
    % upper level camera shooting and display
    function [im, exif] = imread(self)
    
      url  = self.actTakePicture;
      % get the extension
      [p, f, e] = fileparts(char(url));
      
      % then get URL and display it
      file = [ tempname e ]
      im   = urlwrite(char(url), file);
      im   = imread(im);
      if nargout > 1, exif = imfinfo(file); end
      delete(file);
     
    end % imread
    
    function h = image(self)
      h = image(self.imread);
    end
    
    function h = plot(self)
      h = image(self.imread);
    end
    
    % Camera settings ----------------------------------------------------------
    function ret = iso(self, value)
      % iso(s):        get the ISO setting as a string (can be 'AUTO')
      % iso(s, 'iso'): set the ISO setting as a string (can be 'AUTO')
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
    end
    
    function ret = mode(self, value)
      % mode(s):         get the shooting Mode (e.g. PASM)
      % mode(s, 'PASM'): set the shooting Mode (e.g. PASM) as a string
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
    end
    
    function ret = timer(self, value)
      % timer(s):      get the self Timer setting
      % timer(s, val): set the self Timer setting in seconds
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
    end
    
    function ret = shutter(self, value)
      % shutter(s):      get the shutter speed setting (S mode)
      % shutter(s, val): set the shutter speed setting (S mode) as a string
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
    end
    
    function ret = fnumber(self, value)
      % fnumber(s):      get the F/D number (apperture) setting (A mode)
      % fnumber(s, val): set the F/D number (apperture) setting (A mode) as a string
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
    end
    
    function ret = white(self, value)
      % white(s):      get the white balance setting
      % white(s, val): set the white balance setting
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
    end
    
    
  end % methods
  
end

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
    if  isfield(message, 'result') && isfield(message, 'id') && message.id == 1
      message = message.result;
    elseif isfield(message, 'error')
      message = message.error;
    end
  end
  if iscell(message) && numel(message) == 1
    message = message{1};
  end
end

