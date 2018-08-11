function [ret, message, self] = api_gphoto2(self, post, target)
  % api_gphoto2: emulate the Sony API commands through gphoto calls

  % first decode the JSON command
  json = loadjson(post);
  ret  = 0; % non zero for error.
  message = struct(); % fields: result, error
  
  % the JSON message contains:
  % method: command
  % params: value
  
  switch json.method

  case 'getApplicationInfo'
    gphoto_config1 = gphoto2_getconfig('deviceversion');
    gphoto_config2 = gphoto2_getconfig('cameramodel');
    message = sprintf('%s %i', ...
      gphoto_config2.cameramodel.Current, ...
      gphoto_config1.deviceversion.Current);
    
  case 'getEvent'
    % store current settings into object properties
    %  poke all config
    gphoto_config = gphoto2_getconfig;
    status        = gphoto2status(gphoto_config);
    message = struct2cell(status);
        
  case 'startRecMode'
    % NOOP: done to start the remote, which is always active with gphoto
        
  case 'actTakePicture'
    %    gphoto2 --capture-image-and-download
    %        does not store image on camera. Can be used for continuous liveview (remove delay)
    %        all files stored only on computer, can not get/see files on camera.
    
        
    % return image path as cellstr
    message = gphoto2_capture;
        
  case 'getCameraFunction' % / avContent (delete)
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  case 'startLiveview'
    % can be very slow...
    message = gphoto2_liveview(self, fullfile(tempdir, 'LiveView.jpg'));

  case 'stopLiveView'
%    restore image quality
%    restore self timer
%    --set-config imagequality=ID
        
  case 'getIsoSpeedRate'                            % ISO
    gphoto_config= gphoto2_getconfig('iso');
    message = gphoto_config.iso.Current;
        
  case 'getSupportedIsoSpeedRate'
    gphoto_config= gphoto2_getconfig('iso');
    message = gphoto_config.iso.Choice;
        
  case 'setIsoSpeedRate'
    % --set-config iso=ID
    message = gphoto2_setconfig('iso', json.params, self.available.iso);
        
  case 'getExposureMode'                            % PASM
    gphoto_config= gphoto2_getconfig('expprogram');
    message = gphoto_config.expprogram.Current;
        
  case 'getSupportedExposureMode'
    gphoto_config= gphoto2_getconfig('expprogram');
    message = gphoto_config.expprogram.Choice;
        
  case 'setExposureMode'
    % --set-config exposurecompensation=id
    message = gphoto2_setconfig('expprogram', json.params, self.available.mode);
        
  case 'getSelfTimer'                               % Timer etc
    gphoto_config= gphoto2_getconfig('capturemode');
    message = gphoto_config.capturemode.Current;
        
  case 'getSupportedSelfTimer'
    gphoto_config= gphoto2_getconfig('capturemode');
    message = gphoto_config.capturemode.Choice;
        
  case 'setSelfTimer'
    % --set-config capturemode=ID
    message = gphoto2_setconfig('capturemode', json.params, self.available.timer);
        
  case 'getShutterSpeed'                            % shutter speed
    gphoto_config= gphoto2_getconfig('shutterspeed');
    message = gphoto_config.shutterspeed.Current;
        
  case 'getSupportedShutterSpeed'
    gphoto_config= gphoto2_getconfig('shutterspeed');
    message = []; % gphoto_config.shutterspeed.Choice;
        
  case 'setShutterSpeed'
    % --set-config shutterspeed=ID
    message = gphoto2_setconfig('shutterspeed', json.params, []);
        
  case 'getFNumber'                                 % F value
    gphoto_config= gphoto2_getconfig('f-number');
    message = gphoto_config.f0x2Dnumber.Current;
        
  case 'getSupportedFNumber'
    gphoto_config= gphoto2_getconfig('f-number');
    message = []; % gphoto_config.f0x2Dnumber.Bottom : Top
        
  case 'setFNumber' 
    % --set-config f-number=ID
    message = gphoto2_setconfig('f-number', json.params, self.available.fnumber);
        
  case 'getWhiteBalance'                            % while balance
    gphoto_config= gphoto2_getconfig('whitebalance');
    message = gphoto_config.whitebalance.Current;
        
  case 'getSupportedWhiteBalance'
    gphoto_config= gphoto2_getconfig('whitebalance');
    message = gphoto_config.whitebalance.Choice;
        
  case 'setWhiteBalance' 
    % --set-config whitebalance=ID
    message = gphoto2_setconfig('whitebalance', json.params, self.available.white);
        
  case 'getExposureCompensation'                    % ExposureCompensation
    gphoto_config= gphoto2_getconfig('exposurecompensation');
    message = gphoto_config.exposurecompensation.Current;
        
  case 'getSupportedExposureCompensation'
    gphoto_config= gphoto2_getconfig('exposurecompensation');
    message = gphoto_config.exposurecompensation.Choice;
        
  case 'setExposureCompensation'
    % --set-config exposurecompensation=ID
    message = gphoto2_setconfig('exposurecompensation', json.params, self.available.exp);
        
  case 'setZoomSetting'
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  case 'actZoom'
    disp([ mfilename ': unsupported feature: ' json.method ])
  
  case 'getStillQuality'                               % Image Quality (RAW, JPEG)
    gphoto_config= gphoto2_getconfig('imagequality');
    message = gphoto_config.imagequality.Current;
        
  case 'getSupportedStillQuality'
    gphoto_config= gphoto2_getconfig('imagequality');
    message = gphoto_config.imagequality.Choice;
        
  case 'setStillQuality'
    % --set-config capturemode=ID
    message = gphoto2_setconfig('imagequality', json.params, self.available.quality);
        
  end % switch method
        
end % api_gphoto2
        
% ------------------------------------------------------------------------------
function gphoto_config = gphoto2_getconfig(config)
% gphoto2_getconfig: get the camera configuration

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 1, config = []; end
  if ~isempty(config)
    cmd = [ precmd 'gphoto2 -q ' ]; 
    % handle multiple config
    if ~iscell(config), config = cellstr(config); end
    for index=1:numel(config)
      cmd = [ cmd ' --get-config ' config{index} ];
    end
  else
    cmd = [ precmd 'gphoto2 --list-all-config -q' ];
  end
  
  [ret, message] = system(cmd);
  if ret ~= 0
    disp(cmd)
    disp(message)
    error('GPhoto is not available, or camera is not connected.');
  end

  % now we split with '/main' entries
  t = textscan(message, '%s','Delimiter','\n'); % into lines
  t = t{1};
  main = find(strncmp(t, '/main', 5));
  if isempty(main), main = 1; end
  gphoto_config = struct();
  
  % analyse result
  for index=1:numel(main)
    % extract the block
    block_start = main(index);
    if index==numel(main)
      block_end = numel(t);
    else
      block_end = main(index+1);
    end
    
    % block name
    if ~isempty(config), n = config{index};
    else
      n  = t{block_start};
      [r,n] = fileparts(n); n(~isstrprop(n, 'alphanum')) = '_';
    end
    if ~isvarname(n), n= genvarname(n); end
    name = n;
    % block fields
    block = t(block_start:block_end);
    block = str2struct(block);
    gphoto_config.(name) = block;
  end
end % gphoto2_getconfig

% ------------------------------------------------------------------------------
function message = gphoto2_setconfig(config, value, choices)
% gphoto2_setconfig: set the camera configuration

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 1, config = []; end
  if nargin < 2, value  = [];  end
  if nargin < 3, choices = [];  end
  if isempty(configs) || isempty(values)
    message = [];
    return;
  end
  
  cmd = [ precmd 'gphoto2 -q' ];
  
  % search for value in choices
  value = findValueInChoices(value, choices);
  
  % now assemble the command line
  cmd = [ cmd ' --set-config ' config '=' value ];

  
 
  disp(cmd)
  [ret, message] = system(cmd);
  if ret ~= 0
    disp(cmd)
    disp(message)
    disp([ mfilename ': GPhoto failed setting ' config '=' value ]);
    message = 'ERROR';
  end
end % gphoto2_setconfig

% ------------------------------------------------------------------------------

function filename = gphoto2_capture(filename)
% gphoto2_capture: capture an image (single shoot)

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 1, filename = []; end
  if isempty(filename)
    p = tempname;
    mkdir(p);
    f = '%f';
    e = '';
  else
    % check if we have specified an extension
    [ p,f,e ] = fileparts(filename);
    if isempty(p), p = pwd; end
    if isempty(f), f = '%f'; end
  end

  % handle incomplete information
  if isdir(fullfile(p,f)) p=fullfile(p,f); f = ''; end
  if isempty(f) f= '%f';  end
  if isempty(e) e= '.%C'; end
  gfile = fullfile(p, [f e ]);
  
  cmd = [ precmd 'gphoto2 --capture-image-and-download ' ...
    '--filename=''' gfile ''' --force-overwrite -q' ];
  disp(cmd);
  [ret, message] = system(cmd);
  if ret ~= 0
    disp(cmd)
    disp(message)
    disp([ mfilename ': GPhoto failed taking image (capture)' ]);
    filename = '';
  else
    % read files and return image path
    % replace any '%' token in gphoto by '*'
    
    pat = '%a %A %b %B %d %H %k %I %l %j %m %M %S %y %% %n %C %f %F %:';
    pat = textscan(pat, '%s', 'Delimiter',' '); pat=pat{1};
    
    for tok = pat'
      gfile = strrep(gfile, tok{1}, '*');
    end
    
    files = dir(gfile);
    filename = {};
    for index=1:numel(files)
      this = files(index);
      if ~this.isdir
        filename{end+1} = fullfile(p, this.name);
      end
    end
  end

end % gphoto2_capture

function message = gphoto2_liveview(self, filename)
% gphoto2_liveview: capture a 'fast' image for live view

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  % get 'fast' settings, capture, and restore
  imagequality = findValueInChoices(self.imageQuality,        self.available.quality);
  capturemode  = findValueInChoices(self.timer,               self.available.timer); 
  imagequality0= findValueInChoices(self.available.quality{1},self.available.quality);
  capturemode0 = findValueInChoices(self.available.timer{1},  self.available.timer);
  
  cmd = [ precmd 'gphoto2 -q' ...
    ' --set-config imagequality=' imagequality0  ...
    ' --set-config capturemode='  capturemode0 ...
    ' --capture-image-and-download --force-overwrite ' ...
    '--filename=''' filename '''' ...
    ' --set-config imagequality=' imagequality ...
    ' --set-config capturemode=' capturemode ];

  disp(cmd)
  [ret, message] = system(cmd);
  
  if ret ~= 0
    disp(cmd)
    disp(message)
    disp([ mfilename ': GPhoto failed liveView' ]);
    message = '';
  else message = filename;
  end
    
end % gphoto2_liveview

% ------------------------------------------------------------------------------
function status = gphoto2status(gphoto_config)
  
  status = struct();
  % reformat status in more readable struct
  try
  status.exposureMode.type = 'exposureMode';
  status.exposureMode.label               = gphoto_config.expprogram.Label;
  status.exposureMode.available           = gphoto_config.expprogram.Choice;
  status.exposureMode.currentExposureMode = gphoto_config.expprogram.Current;
  end
  try
  status.cameraStatus = gphoto_config.cameramodel.Current;
  end
  try
  status.selfTimer.type = 'selfTimer';
  status.selfTimer.label                  = gphoto_config.capturemode.Label;
  status.selfTimer.available              = gphoto_config.capturemode.Choice;
  status.selfTimer.currentSelfTimer       = gphoto_config.capturemode.Current;
  end
  
  status.zoomInformation.zoomPosition     = [];
  
  status.shootMode.currentShootMode       = 'still';
  
  try
  status.exposureCompensation.type = 'exposureCompensation';
  status.exposureCompensation.label       = gphoto_config.exposurecompensation.Label;
  status.exposureCompensation.available   = gphoto_config.exposurecompensation.Choice;
  status.exposureCompensation.currentExposureCompensation = ...
    gphoto_config.exposurecompensation.Current;
  end
  try
  status.fNumber.type = 'fNumber';
  status.fNumber.label                    = gphoto_config.f_number.Label;
  status.fNumber.available                = [];
  status.fNumber.currentFNumber           = gphoto_config.f_number.Current;
  end
  try
  status.focusMode.type = 'focusMode';
  status.focusMode.label                  = gphoto_config.focusmode.Label;
  status.focusMode.available              = gphoto_config.focusmode.Choice;
  status.focusMode.currentFocusMode       = gphoto_config.focusmode.Current;
  end
  try
  status.isoSpeedRate.type = 'isoSpeedRate';
  status.isoSpeedRate.label               = gphoto_config.iso.Label;
  status.isoSpeedRate.available           = gphoto_config.iso.Choice;
  status.isoSpeedRate.currentIsoSpeedRate = gphoto_config.iso.Current;
  end
  try
  status.shutterSpeed.type = 'shutterSpeed';
  status.shutterSpeed.label               = gphoto_config.shutterspeed.Label;
  status.shutterSpeed.available           = [];
  status.shutterSpeed.currentShutterSpeed = gphoto_config.shutterspeed.Current;
  end
  try
  status.whiteBalance.type = 'whiteBalance';
  status.whiteBalance.label               = gphoto_config.whitebalance.Label;
  status.whiteBalance.available           = gphoto_config.whitebalance.Choice;
  status.whiteBalance.currentWhiteBalanceMode = gphoto_config.whitebalance.Current;
  end
  try
  status.imageQuality.type = 'imageQuality';
  status.imageQuality.label               = gphoto_config.imagequality.Label;
  status.imageQuality.available           = gphoto_config.imagequality.Choice;
  status.imageQuality.currentImageQuality = gphoto_config.imagequality.Current;
  end
  
  status.gphoto = gphoto_config;
end % gphoto2status
        
function value = findValueInChoices(value, choices)
% findValueInChoices: search for value in choices
  if ischar(value)
    val_num = str2num(value); 
    val_char= value;
  else 
    val_char= num2str(value);
    val_num = value;
  end
  
  val_char = strrep(val_char, '\"',''); % remove 'second' in char value
  % handle long name for modes
  switch val_char
  case 'Program Auto'; val_char = 'P';
  case 'Aperture';     val_char = 'A';
  case 'Shutter';      val_char = 'S';
  case 'Manual';       val_char = 'M';
  end

  % lookfor value within choices -> ID
  if ~isempty(choices)
    for index=1:numel(choices)
      this = choices{index};
      if isnumeric(this)
        if isscalar(this)
          if val_num == this,    value = this;    break; end
        elseif numel(this) == 2
          if val_num == this(2), value = this(1); break; end
        end
      elseif ischar(this)
        [t, r] = strtok(this); r = strtrim(r);
        if     strcmp(r, val_char),    value = t; break;
        elseif strcmp(t, val_char),    value = t; break;
        elseif strcmp(this, val_char), value = val_char; break; end
      end
    end
  end
  
  if isnumeric(value), value = num2str(value); 
  else 
    [t, r] = strtok(value);
    if isfinite(str2double(t)) value = t; end
  end
end % findValueInChoices
