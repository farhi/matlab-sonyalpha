function [ret, message] = api_gphoto2(self, post, target)
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
    gphoto_config = gphoto2_getstatus('deviceversion');
    message = gphoto_config.deviceversion.Current;
    
  case 'getEvent'
    % store current settings into object properties
    %  poke all config
    gphoto_config = gphoto2_getstatus;
    status        = gphoto2status(gphoto_config);
    message = struct2cell(status);
        
  case 'startRecMode'
    % NOOP: done to start the remote, which is always active with gphoto
        
  case 'actTakePicture'
%    gphoto2 --capture-image-and-download
%        does not store image on camera. Can be used for continuous liveview (remove delay)
%        all files stored only on computer, can not get/see files on camera.
        
    % return image path
        
  case 'getCameraFunction' % / avContent (delete)
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  case 'startLiveview'
%    switch to JPEG only and get 1 image every second
%    remove self timer
%    --set-config imagequality=ID
        
  case 'stopLiveView'
%    restore image quality
%    restore self timer
%    --set-config imagequality=ID
        
  case 'getIsoSpeedRate'
    gphoto_config= gphoto2_getstatus('iso');
    message = gphoto_config.iso.Current;
        
  case 'getSupportedIsoSpeedRate'
    gphoto_config= gphoto2_getstatus('iso');
    message = gphoto_config.iso.Choice;
        
  case 'setIsoSpeedRate'
    % --set-config iso=ID
        
  case 'getExposureMode'
    gphoto_config= gphoto2_getstatus('expprogram');
    message = gphoto_config.expprogram.Current;
        
  case 'getSupportedExposureMode'
    gphoto_config= gphoto2_getstatus('expprogram');
    message = gphoto_config.expprogram.Choice;
        
  case 'setExposureMode'
    % --set-config exposurecompensation=id
        
  case 'getSelfTimer'
    gphoto_config= gphoto2_getstatus('capturemode');
    message = gphoto_config.capturemode.Current;
        
  case 'getSupportedSelfTimer'
    gphoto_config= gphoto2_getstatus('capturemode');
    message = gphoto_config.capturemode.Choice;
        
  case 'setSelfTimer'
    % --set-config capturemode=ID
        
  case 'getShutterSpeed'
    gphoto_config= gphoto2_getstatus('shutterspeed');
    message = gphoto_config.shutterspeed.Current;
        
  case 'getSupportedShutterSpeed'
    gphoto_config= gphoto2_getstatus('shutterspeed');
    message = []; % gphoto_config.shutterspeed.Choice;
        
  case 'setShutterSpeed'
    % --set-config shutterspeed=ID
        
  case 'getFNumber'
    gphoto_config= gphoto2_getstatus('f-number');
    message = gphoto_config.f0x2Dnumber.Current;
        
  case 'getSupportedFNumber'
    gphoto_config= gphoto2_getstatus('f-number');
    message = []; % gphoto_config.f0x2Dnumber.Bottom : Top
        
  case 'setFNumber'
    % --set-config f-number=ID
        
  case 'getWhiteBalance'
    gphoto_config= gphoto2_getstatus('whitebalance');
    message = gphoto_config.whitebalance.Current;
        
  case 'getSupportedWhiteBalance'
    gphoto_config= gphoto2_getstatus('whitebalance');
    message = gphoto_config.whitebalance.Choice;
        
  case 'setWhiteBalance'
    % --set-config whitebalance=ID
        
  case 'getExposureCompensation'
    gphoto_config= gphoto2_getstatus('exposurecompensation');
    message = gphoto_config.exposurecompensation.Current;
        
  case 'getSupportedExposureCompensation'
    gphoto_config= gphoto2_getstatus('exposurecompensation');
    message = gphoto_config.exposurecompensation.Choice;
        
  case 'setExposureCompensation'
    % --set-config exposurecompensation=ID
        
  case 'setZoomSetting'
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  case 'actZoom'
    disp([ mfilename ': unsupported feature: ' json.method ])
        
  end % switch method
        
end % api_gphoto2
        
% ------------------------------------------------------------------------------
function gphoto_config = gphoto2_getstatus(config)
  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  if nargin < 1, config = []; end
  if ~isempty(config)
    cmd = [ precmd 'gphoto2 --get-config ' config ' -q' ];
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
    if ~isempty(config), n = config;
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
end % gphoto2_getstatus
  
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
end % gphoto2status
        
