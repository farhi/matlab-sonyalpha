function [ret, message, self] = api_gphoto2(self, post, target)
  % api_gphoto2: emulate the Sony API commands through gphoto calls
  
  persistent exe
  
  if isempty(exe)
    exe = gphoto_executable;
  end

  % first decode the JSON command
  json = loadjson(post);
  ret  = 0; % non zero for error.
  message = struct(); % fields: result, error
  
  % the JSON message contains:
  % method: command
  % params: value
  
  switch json.method

  case 'getApplicationInfo'
    gphoto_config1 = gphoto2_getconfig(exe, 'deviceversion');
    gphoto_config2 = gphoto2_getconfig(exe, 'cameramodel');
    message = sprintf('%s %i', ...
      gphoto_config2.cameramodel.Current, ...
      gphoto_config1.deviceversion.Current);
    
  case 'getEvent'
    % store current settings into object properties
    %  poke all config
    gphoto_config = gphoto2_getconfig(exe);
    status        = gphoto2status(gphoto_config);
    message = struct2cell(status);
        
  case 'startRecMode'
    % NOOP: done to start the remote, which is always active with gphoto
        
  case 'actTakePicture'
    %    gphoto2 --capture-image-and-download
    %        does not store image on camera. Can be used for continuous liveview (remove delay)
    %        all files stored only on computer, can not get/see files on camera.
    
        
    % return image path as cellstr
    message = gphoto2_capture(exe);
        
  case 'getCameraFunction' % / avContent (delete)
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  case 'startLiveview'
    % can be very slow...
    message = gphoto2_liveview(exe, self, fullfile(tempdir, 'LiveView.jpg'));

  case 'stopLiveView'
%    restore image quality
%    restore self timer
%    --set-config imagequality=ID
        
  case 'getIsoSpeedRate'                            % ISO
    gphoto_config= gphoto2_getconfig(exe, 'iso');
    message = gphoto_config.iso.Current;
        
  case 'getSupportedIsoSpeedRate'
    gphoto_config= gphoto2_getconfig(exe, 'iso');
    message = gphoto_config.iso.Choice;
        
  case 'setIsoSpeedRate'
    % --set-config iso=ID
    message = gphoto2_setconfig(exe, 'iso', json.params, self.available.iso);
        
  case 'getExposureMode'                            % PASM
    gphoto_config= gphoto2_getconfig(exe, 'expprogram');
    message = gphoto_config.expprogram.Current;
        
  case 'getSupportedExposureMode'
    gphoto_config= gphoto2_getconfig(exe, 'expprogram');
    message = gphoto_config.expprogram.Choice;
        
  case 'setExposureMode'
    % --set-config exposurecompensation=id
    message = gphoto2_setconfig(exe, 'expprogram', json.params, self.available.mode);
        
  case 'getSelfTimer'                               % Timer etc
    gphoto_config= gphoto2_getconfig(exe, 'capturemode');
    message = gphoto_config.capturemode.Current;
        
  case 'getSupportedSelfTimer'
    gphoto_config= gphoto2_getconfig(exe, 'capturemode');
    message = gphoto_config.capturemode.Choice;
        
  case 'setSelfTimer'
    % --set-config capturemode=ID
    message = gphoto2_setconfig(exe, 'capturemode', json.params, self.available.timer);
        
  case 'getShutterSpeed'                            % shutter speed
    gphoto_config= gphoto2_getconfig(exe, 'shutterspeed');
    message = gphoto_config.shutterspeed.Current;
        
  case 'getSupportedShutterSpeed'
    gphoto_config= gphoto2_getconfig(exe, 'shutterspeed');
    message = []; % gphoto_config.shutterspeed.Choice;
        
  case 'setShutterSpeed'
    % --set-config shutterspeed=ID
    message = gphoto2_setconfig(exe, 'shutterspeed', json.params, []);
        
  case 'getFNumber'                                 % F value
    gphoto_config= gphoto2_getconfig(exe, 'f-number');
    message = gphoto_config.f0x2Dnumber.Current;
        
  case 'getSupportedFNumber'
    gphoto_config= gphoto2_getconfig(exe, 'f-number');
    message = []; % gphoto_config.f0x2Dnumber.Bottom : Top
        
  case 'setFNumber' 
    % --set-config f-number=ID
    message = gphoto2_setconfig(exe, 'f-number', json.params, self.available.fnumber);
        
  case 'getWhiteBalance'                            % while balance
    gphoto_config= gphoto2_getconfig(exe, 'whitebalance');
    message = gphoto_config.whitebalance.Current;
        
  case 'getSupportedWhiteBalance'
    gphoto_config= gphoto2_getconfig(exe, 'whitebalance');
    message = gphoto_config.whitebalance.Choice;
        
  case 'setWhiteBalance' 
    % --set-config whitebalance=ID
    message = gphoto2_setconfig(exe, 'whitebalance', json.params, self.available.white);
        
  case 'getExposureCompensation'                    % ExposureCompensation
    gphoto_config= gphoto2_getconfig(exe, 'exposurecompensation');
    message = gphoto_config.exposurecompensation.Current;
        
  case 'getSupportedExposureCompensation'
    gphoto_config= gphoto2_getconfig(exe, 'exposurecompensation');
    message = gphoto_config.exposurecompensation.Choice;
        
  case 'setExposureCompensation'
    % --set-config exposurecompensation=ID
    message = gphoto2_setconfig(exe, 'exposurecompensation', json.params, self.available.exp);
        
  case 'setZoomSetting'
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  case 'actZoom'
    disp([ mfilename ': unsupported feature: ' json.method ])
  
  case 'getStillQuality'                               % Image Quality (RAW, JPEG)
    gphoto_config= gphoto2_getconfig(exe, 'imagequality');
    message = gphoto_config.imagequality.Current;
        
  case 'getSupportedStillQuality'
    gphoto_config= gphoto2_getconfig(exe, 'imagequality');
    message = gphoto_config.imagequality.Choice;
        
  case 'setStillQuality'
    % --set-config capturemode=ID
    message = gphoto2_setconfig(exe, 'imagequality', json.params, self.available.quality);
        
  end % switch method
        
end % api_gphoto2
        
% ------------------------------------------------------------------------------
function gphoto_config = gphoto2_getconfig(exe, config)
% gphoto2_getconfig: get the camera configuration

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 2, config = []; end
  if ~isempty(config)
    cmd = [ precmd exe ' -q ' ]; 
    % handle multiple config
    if ~iscell(config), config = cellstr(config); end
    for index=1:numel(config)
      cmd = [ cmd ' --get-config ' config{index} ];
    end
  else
    cmd = [ precmd exe  ' --list-all-config -q' ];
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
function message = gphoto2_setconfig(exe, config, value, choices)
% gphoto2_setconfig: set the camera configuration

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 2, config = [];  end
  if nargin < 3, value  = [];  end
  if nargin < 4, choices = []; end
  if isempty(config) || isempty(value)
    message = [];
    return;
  end
  
  cmd = [ precmd exe ' -q' ];
  
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

function filename = gphoto2_capture(exe, filename)
% gphoto2_capture: capture an image (single shot)

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 2, filename = []; end
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
  
  cmd = [ precmd exe ' --capture-image-and-download ' ...
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

% ------------------------------------------------------------------------------

function message = gphoto2_liveview(exe, self, filename)
% gphoto2_liveview: capture a 'fast' image for live view

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 3, filename = ''; end
  if isempty(filename), filename = fullfile(tempdir, 'LiveView.jpg'); end
  
  % get 'fast' settings, capture, and restore
  imagequality = findValueInChoices(self.imageQuality,        self.available.quality);
  capturemode  = findValueInChoices(self.timer,               self.available.timer); 
  imagequality0= findValueInChoices(self.available.quality{1},self.available.quality);
  capturemode0 = findValueInChoices(self.available.timer{1},  self.available.timer);
  
  cmd = [ precmd exe ' -q' ...
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

% ------------------------------------------------------------------------------

function value = findValueInChoices(value, choices)
% findValueInChoices: search for value in choices
  if iscell(value), value = [ value{:} ]; end
  if ischar(value)
    val_num = str2num(value); 
    val_char= value;
  else 
    val_char= num2str(value);
    val_num = value;
  end
  
  if any(val_char == '"') % shutter time
    val_char = strrep(val_char, '\"',''); % remove 'second' in char value
    val_char = strrep(val_char, '"',''); 
    value    = str2num(val_char);
  end

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

% ------------------------------------------------------------------------------

function g = gphoto_executable
  % search gphoto2 binary
  
  g = ''; 
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ;';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ; '; 
  else           precmd=''; end
  
  if ispc, ext='.exe'; else ext=''; end
  
  % try in order: global(system), local, local_arch
  for try_target={ [ 'gphoto2' ext ], 'gphoto2' }
      
    [status, result] = system([ precmd try_target{1} ' --version' ]); % run from Matlab

    if status == 0
        % the executable is there.
        g = try_target{1};
        disp([ '  GPhoto         (https://www.gphoto.org/) as: ' g ]);
        break
    end
  end
  
  if isempty(g)
    error([ mfilename ': GPHOTO is not available. Install it from gphoto.org' ])
  end
end % gphoto_executable
