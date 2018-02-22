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
  %   exp:                set/get the exposure compensation
  %   focus:              set/get the focus mode
  %   zoom:               zoom in or out
  %
  %   urlread:            take a picture and return the distant URL (no download)
  %   imread:             take a picture and download the RGB image (no display)
  %   image:              take a picture and display it
  %   plot:               show the live-view image (not stored)
  %
  %   continuous:         start/stop continuous shooting with current settings.
  %   timelapse:          start/stop timelapse  shooting with current settings.
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
    url           = 'http://192.168.122.1:8080';
    
    % settings, updated on getstatus
    exposureMode  = 'P';
    cameraStatus  = 'IDLE';
    selfTimer     = 0;
    zoomPosition  = -1;
    shootMode     = 'still';
    exposureCompensation = 0; % in EV
    fNumber       = '2.8';
    focusMode     = 'AF-S';
    isoSpeedRate  = 'AUTO';
    shutterSpeed  = '1/60';
    whiteBalance  = 'Auto WB';
    
    status        = struct();
    available     = struct();
    version       = '2.40';
  end % properties
  
  properties (Access=private)
    updateTimer   = ''; % a timer object for auto getstatus every 5 s.
    
    % continuous/timelapse modes
    timelapse_clock = 0;    % clock when last shot
    timelapse_interval = 0; % time between shots
    figure = [];

  end % properties
  
  methods
    function self = sonyalpha(url)
      % sonyalpha: initialize the remote control for Sony Alpha Camera
      %
      %   s = sonyalpha;
      %
      % the default url is http://192.168.122.1:8080/sony/camera
      if nargin > 1
        self.url = url;
      end
      
      self.version = self.api('getApplicationInfo');
      if iscell(self.version), self.version = [ self.version{:} ]; end
      
      ret = self.api('startRecMode');
      self.getstatus;

      for f = {'mode','iso','timer','fnumber','white','exp','shutter','focus'}
        self.available.(f{1}) = feval(f{1}, self, 'available');
        this = self.available.(f{1});
        if strcmp(f{1}, 'exp')
          self.available.(f{1}) = unique(round((min(this):max(this))/3));
        elseif strcmp(f{1}, 'fnumber') && isempty(this)
          self.available.(f{1}) = {'2.8' '3.5' '4.0' '4.5' '5.0' '5.6' '6.3' ...
           '7.1' '8.0' '9.0' '10' '11' '13' '16' '20' '22' };
        elseif strcmp(f{1}, 'shutter') && isempty(this)
          self.available.(f{1}) = {'30"' '25"' '20"' '15"' '10"' '5"' '4"' ...
          '3"' '2"' '1"' '1/10' '1/30' '1/60' '1/125' '1/250' '1/400' '1/1000' };
        end
      end
       
      % init timer for regular updates, timelapse, etc
      self.updateTimer  = timer('TimerFcn', @TimerCallback, ...
          'Period', 5.0, 'ExecutionMode', 'fixedDelay', ...
          'Name', mfilename);
      set(self.updateTimer, 'UserData', self);
      start(self.updateTimer);

      disp([ mfilename ': [' datestr(now) '] Welcome to Sony Alpha ' char(self.version) ' at ' char(self.url) ]);
      plot_window(self);

    end % sonyalpha
    
    % main communication method (low-level)
    function message = curl(self, post, target)
      % prepare curl command
      if ismac,      precmd = 'DYLD_LIBRARY_PATH= ;';
      elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
      else           precmd=''; end
      
      if nargin < 3, target = 'camera'; end
      url = fullfile(self.url, 'sony', target);
      
      cmd = [ 'curl -d ''' post ''' ' url ];
      
      % evaluate command
      [ret, message]=system([ precmd  cmd ]);
      
      if ret % error
        disp(cmd)
        disp([ mfilename ': Connection failed: ' url])
        error(message);
      end
      
      % decode JSON output into struct
      try
        if ~isempty(message)
          message = strrep(message, '\/','/');
          message = loadjson(message); % We use JSONlab reader which is more robust
        end
      catch
        disp(cmd)
        message
        error([ mfilename ': Invalid JSON result. Perhaps the connection failed ?' ])
      end

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
    
    % INFO stuff
    function status = getstatus(self)
      % getstatus: get the Camera status and all settings
      json = '{"method": "getEvent", "params": [false], "id": 1, "version": "1.2"}';
      message = curl(self, json);
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
      try; self.exposureMode = status.exposureMode.currentExposureMode; end
      try; self.cameraStatus = status.cameraStatus; end
      try; self.selfTimer    = status.selfTimer.currentSelfTimer; end
      try; self.zoomPosition = status.zoomInformation.zoomPosition; end
      try; self.shootMode    = status.shootMode.currentShootMode; end
      try; self.exposureCompensation = ...
             status.exposureCompensation.currentExposureCompensation/3; end
      try; self.fNumber      = status.fNumber.currentFNumber; end
      try; self.focusMode    = status.focusMode.currentFocusMode; end
      try; self.isoSpeedRate = status.isoSpeedRate.currentIsoSpeedRate; end
      try; self.shutterSpeed = status.shutterSpeed.currentShutterSpeed; end
      try; self.whiteBalance = status.whiteBalance.currentWhiteBalanceMode; end

    end % getstatus
    
    % generic API call ---------------------------------------------------------
    
    function ret = api(self, method, value, service)
      % api('method'):        call the given API method call (without argument)
      % api('method', param): call the given API method call (with argument)
      % api(..., service):    call the given API method call, for the API service.
      %    Default is service='camera'. Other choice is 'avContent'.
      if nargin < 4, service='camera'; end
      if nargin < 3 || isempty(value)
        json = [ '{"method": "' method '","params": [],"id": 1,"version": "1.0"}' ];
      else
        if isnumeric(value),  value = num2str(value);
        elseif ischar(value), value = [ '"' value '"' ];
        elseif islogical(value)
          if value, value = 'true'; else value = 'false'; end
        end
        json = [ '{"method": "' method '","params": [' value '],"id": 1,"version": "1.0"}' ];
      end
      
      ret  = curl(self, json, service);
    end % api
    
    % Camera Shooting ----------------------------------------------------------
    function ret = start(self)
      % start: set the camera into shooting mode
      ret = self.api('startRecMode');
      self.getstatus;
      if strcmp(self.updateTimer.Running, 'off') start(self.updateTimer); end
    end % start
    
    function ret = stop(self)
      % stop: stop the camera shooting.
      % 
      % start(s) must be used to be able to take pictures again.
      ret = self.api('stopRecMode');
      self.timelapse_clock = 0;
    end % stop
    
    function url = urlread(self)
      % urlread: take a picture and return the distant URL (no upload)
      %
      % Must have used 'start' before (e.g. at init).
      % The resulting image is the 'postview' one, e.g. 2M pixels. The original
      % image remains on the camera.
      url = self.api('actTakePicture');
      if iscellstr(url)
        url = char(url);
      else
        self.start; % try to start the camera
        disp([ mfilename ': camera is not ready.' ]);
      end
    end % urlread
    
    function [im,url] = urlwrite(self, filename)
      % urlread: take a picture, and download it as a local file
      %
      % [im, url] = urlwrite(s, filename)
      %   write image into 'filename' and return the distant image URL.
      %
      % Must have used 'start' before (e.g. at init).
      % The resulting image is the 'postview' one, e.g. 2M pixels. The original
      % image remains on the camera.
      
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
    
    function urldelete(self, filename)
      % delete files from the camera using the following sequence of calls:
      % 
      %  setCameraFunction to "Contents Transfer"
      %  getSourceList to get storage location
      %  getContentCount to get count of files
      %  getContentList to get list of files on camera
      %  parse content list to get file URI's
      %  deleteContent to delete each file
      curl(self, 'getCameraFunction', 'avContent');
    end % urldelete
    
    function [im, exif] = imread(self)
      % imread: take a picture, and read it as an RGB matrix.
      %
      % [im, exif] = imread(s)
      %   returns the EXIF data.
      %
      % Must have used 'start' before (e.g. at init).
      % The resulting image is the 'postview' one, e.g. 2M pixels. The original
      % image remains on the camera.
      filename = tempname;
      url  = self.urlwrite(filename);
      
      im   = imread(url); % local file
      if nargout > 1, exif = imfinfo(url); end
      delete(url);
     
    end % imread
    
    function [h, im, exif] = image(self)
      % image: take a picture, and display it.
      %
      % [h, im, exif] = image(s)
      %   also return image handle, image RGB matrix and EXIF data.
      %
      % Must have used 'start' before (e.g. at init).
      % The resulting image is the 'postview' one, e.g. 2M pixels. The original
      % image remains on the camera.
      
      [im, exif] = imread(self);
      h = image(im);
    end % image
    
    function h = plot(self)
      % plot: get a live-view image, display it, but does not store it.
      %
      % The response time is around 2s.
      
      % TODO:
      % display pointer(s) for alignement (and keep them)
      %
      % we could set the ffmpeg as a background commands then monitor for the
      % temporary file, and plot when it comes. 
      %
      % could also launch external viewer:
      % gst-launch-1.0 souphttpsrc location=http://192.168.122.1:8080/liveview/liveviewstream ! sonyalphademux ! jpegparse ! jpegdec ! videoconvert ! autovideosink
      
      % start the LiveView mode and get a frame
      filename = [ tempname '.jpg' ];
      % get the livestream URL e.g. 
      %   http://192.168.122.1:8080/liveview/liveviewstream
      url = self.api('startLiveview');
      cmd = [ 'ffmpeg  -ss 1 -i ' url ' -frames:v 1 ' filename ];
      [ret, message] = system(cmd);
      self.api('stopLiveView');
      % read the image and display it. delete tmp file.
      im  = imread(filename);
      h   = image(im);
      delete(filename);
    end % plot
    
    % upper level continuous/timelapse modes
    function continuous(self)
      % continuous: take pictures continuously
      %
      % A second call will stop the shooting.
      timelapse(self, 0);
    end % continuous
    
    function timelapse(self, wait)
      % timelapse: take pictures with current settings every 'wait' seconds
      %
      % timelapse(s, wait)
      %   use 'wait' as interval between pictures (in seconds).
      %
      % A second call will stop the shooting.
      if self.timelapse_clock
        % stop after next capture
        self.timelapse_clock = 0;
        disp([ mfilename ': stop shooting' ])
      else
        if nargin < 2
          prompt = {'Enter Time-Lapse Periodicity [s]'};
          name = 'SonyAlpha: Time-Lapse';
          options.Resize='on';
          options.WindowStyle='normal';
          options.Interpreter='tex';
          answer=inputdlg(prompt,name, 1, {'30'}, options);
          if isempty(answer), return; end
          wait=str2double(answer{1});
          if ~isfinite(wait), return; end
        end
        self.timelapse_interval = wait;
        self.timelapse_clock    = clock;
        if wait > 0
          disp([ mfilename ': start shooting (timelapse every ' num2str(wait) ' [s])' ]);
        else
          disp([ mfilename ': start shooting (continuous)' ]);
        end
      end
    end
    
    % Camera settings ----------------------------------------------------------
    function ret = iso(self, value)
      % iso(s):        get the ISO setting as a string (can be 'AUTO')
      % iso(s, 'iso'): set the ISO setting as a string (can be 'AUTO')
      % iso(s, 'supported') return supported ISO settings (strings)
      %
      % The ISO value can be e.g. AUTO 100 200 400 800 1600 3200 6400 12800 25600 
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = api(self, 'getIsoSpeedRate');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedIsoSpeedRate');
      else
        ret = self.api('setIsoSpeedRate', num2str(value));
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
        ret = api(self, 'getExposureMode');
        switch ret
        case 'Program Auto'; ret = 'P';
        case 'Aperture';     ret = 'A';
        case 'Shutter';      ret = 'S';
        case 'Manual';       ret = 'M';
        end
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedExposureMode');
      else
        switch upper(value(1))
        case 'P'; value = 'Program Auto';
        case 'A'; value = 'Aperture';
        case 'S'; value = 'Shutter';
        case 'M'; value = 'Manual';
        end
        ret = self.api('setExposureMode', value);
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
        ret = api(self, 'getSelfTimer');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedSelfTimer');
      else
        ret = self.api('setSelfTimer', num2str(value));
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
        ret = api(self, 'getShutterSpeed');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedShutterSpeed');
      else
        if isnumeric(value)
          if   value >= 1, value = sprintf('%d"',  ceil(value));
          else             value = sprintf('1/%d', ceil(1/value)); end
        end
        ret = self.api('setShutterSpeed', num2str(value));
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
        ret = api(self, 'getFNumber');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedFNumber');
      else
        ret = self.api('setFNumber', num2str(value));
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
        ret = api(self, 'getWhiteBalance');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedWhiteBalance');
      else
        if ischar(value)
          json = [ '{"method": "setWhiteBalance","params": ["' value '", false, -1],"id": 1,"version": "1.0"}' ];
          ret = curl(self, json);
        elseif isnumeric(value)
          value = round(value/100)*100;
          json = [ '{"method": "setWhiteBalance","params": ["Color Temperature", true, ' num2str(value) '],"id": 1,"version": "1.0"}' ];
          ret = curl(self, json);
        end
      end
    end % white
    
    function ret=exp(self, value)
      % exp(s):      get the Exposure Compensation
      % exp(s, val): set the Exposure Compensation as a string
      % exp(s, 'supported') return supported Exposure Compensations (strings)
      %
      % The Exposure Compensation value can be e.g. -9 to 9 in [1/3 EV] units.
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = api(self, 'getExposureCompensation');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedExposureCompensation');
      else
        ret = self.api('setExposureCompensation', value);
      end
    end % exp
    
    function ret=focus(self, value)
      % focus(s):      get the focus mode 
      % focus(s, val): set the focus mode as a string
      % focus(s, 'supported') return supported focus modes (strings)
      %
      % The F/D number value can be e.g. 'AF-S','AF-C','DMF','MF'
      if nargin < 2, value = ''; end
      if isempty(value)
        ret = api(self, 'getFocusMode');
      elseif strcmp(lower(value), 'available') || strcmp(lower(value), 'supported')
        ret = api(self, 'getSupportedFocusMode');
      else
        ret = self.api('setFocusMode', num2str(value));
      end
    end % focus
    
    function ret = zoom(self, d)
      % zoom(s):                get the zoom value
      % zoom(s, 'in' or 'out'): zoom in or out
      if nargin < 2
        ret = self.zoomPosition;
      elseif any(strcmpi(d, {'in','out'}))
        json = [ '{"method": "setZoomSetting","params": ["zoom", "On:Clear Image Zoom"],"id": 1,"version": "1.0"}' ];
        ret = curl(self, json);
        json = [ '{"method": "actZoom","params": ["' d '", "1shot"],"id": 1,"version": "1.0"}' ];
        ret = curl(self, json);
      else ret = [];
      end
    end % zoom
    
  end % methods
  
end % sonyalpha class

% internal communication done with curl ----------------------------------------



% main timer to auto update the camera status and handle e.g. time-lapse
% ----------------------------------------------------------------------

function TimerCallback(src, evnt)
  % TimerCallback: update from timer event
  self = get(src, 'UserData');
  if isvalid(self), self.getstatus; 
  else delete(src); return; end
  
  % update figure Name (if any)
  h = findall(0, 'Tag', 'SonyAlpha');
  if ~isempty(h)
    set(h, 'Name', [ 'SonyAlpha: ' self.cameraStatus ' ' self.url ]);
  end
  
  % handle continuous shooting mode: do something when camera is IDLE
  if strcmpi(self.cameraStatus,'IDLE')
    if any(self.timelapse_clock) && etime(clock, self.timelapse_clock) > self.timelapse_interval
      self.timelapse_clock     = clock;
      url = self.urlread;
      disp([ mfilename ': [' datestr(now) '] image ' url ]);
    end
  end
  
  
  
end % TimerCallback

% simple interface build: show current live-view/last image, and
% camera set-up menu.
% -----------------------------------------------------------------------

function plot_window(self)

  h = findall(0, 'Tag', 'SonyAlpha');
  if isempty(h)
    % build the plot/menu window
    h = figure('Tag', 'SonyAlpha', ...
      'UserData', self, 'MenuBar','none');
      
    % File menu
    m = uimenu(h, 'Label', 'File');
    uimenu(m, 'Label', 'Save',        ...
      'Callback', 'filemenufcn(gcbf,''FileSave'')','Accelerator','s');
    uimenu(m, 'Label', 'Save As...',        ...
      'Callback', 'filemenufcn(gcbf,''FileSaveAs'')');
    uimenu(m, 'Label', 'Print',        ...
      'Callback', 'printdlg(gcbf)');
    uimenu(m, 'Label', 'Close',        ...
      'Callback', 'filemenufcn(gcbf,''FileClose'')', ...
      'Accelerator','w', 'Separator','on');
      
    m0 = uimenu(h, 'Label', 'View');
    labs = { 'Show grid',          'grid on'; ...
             'Brighter',  ''; ...
             'Darker',  ''; ...
             'Add Pointer...',     '' };
    for index1 = 1:size(labs, 1)
      method    = labs{index1,2};
      m1        = uimenu(m0, 'Label', labs{index1,1});
      %  'Callback', [ method(self) ]);
    end
    
    % Settings menu
    m0 = uimenu(h, 'Label', 'Settings');
      
    labs = { 'Mode (Program)',          'mode'; ...
             'Aperture (F/D)',          'fnumber'; ...
             'Shutter Speed',           'shutter'; ...
             'ISO',                     'iso'; ...
             'Exp. Compensation (EV)',  'exp'; ...
             'White Balance',           'white'; ...
             'Focus',                   'focus'; ...
             'Timer',                   'timer' };
    for index1 = 1:size(labs, 1)
      m1        = uimenu(m0, 'Label', labs{index1,1});
      % get list of available choices
      method    = labs{index1,2};
      available = self.available.(method);
      if isnumeric(available)
        available = num2cell(available);
      end
      for index2 = 1:numel(available)
        if isstruct(available{index2})
          available{index2} = getfield(available{index2},'whiteBalanceMode');
        end
        m2 = uimenu(m1, 'Label', num2str(available{index2}));
      %    'Callback', [ method(self, num2str(available{index2})) ]);
      end
    end
  
    m0 = uimenu(h, 'Label', 'Shoot');
    labs = { 'Single',                    @image; ...
             'Continuous Start/Stop',     @continuous; ...
             'Time-Lapse Start/Stop...',  @timelapse };
    for index1 = 1:size(labs, 1)
      method    = labs{index1,2};
      m1        = uimenu(m0, 'Label', labs{index1,1});
     %   'Callback', [ method(self) ]);
    end
    
    % TODO: add pointers
    
    % plot the first image
    plot(self);
  
  else
    if numel(h) > 1, delete(h(2:end)); h=h(1); end
    set(0, 'CurrentFigure',h);
  end
  self.figure = h;
  set(h, 'HandleVisibility','on', 'NextPlot','add');
  set(h, 'Name', [ 'SonyAlpha: ' self.cameraStatus ' ' self.url ]);
end % plot_window

