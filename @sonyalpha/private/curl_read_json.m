function message=curl_read_json(self, message)
  try
    if ~isempty(dir(message))
      message = fileread(message)
    end
  end
  
  % decode JSON output into struct
  if ~any(strcmp(self.url, {'gphoto2','gphoto', 'usb'}))
    try
      if ~isempty(message)
        index = isstrprop(message, 'print');
        message = message(index);
        message = strrep(message, '\/','/');
        message = loadjson(message); % We use JSONlab reader which is more robust
      end
    catch ME
      disp(message)
      disp([ mfilename ': Invalid JSON result. Perhaps the connection failed ?' ])
    end
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
  
end % curl_read_json
