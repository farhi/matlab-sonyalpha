function present = ffmpeg_check
% check if ffmpeg is present

  % required to avoid Matlab to use its own libraries
  if ismac,      precmd = 'DYLD_LIBRARY_PATH= ; DISPLAY= ; ';
  elseif isunix, precmd = 'LD_LIBRARY_PATH= ;  DISPLAY= ; '; 
  else           precmd = ''; end
  
  present = '';
  for totest = { 'ffmpeg' }
    if ~isempty(present), break; end
    for ext={'','.exe','.out'}
      % look for executable and test with various extensions
      [status, result] = system([ precmd totest{1} ext{1} ]);
      if (status == 1 || status == 255) 
        present = [ totest{1} ext{1} ];
        break
      end
    end
  end
  
  if isempty(present)
    disp([ mfilename ': WARNING: FFMPEG executable is not installed. Get it at https://www.ffmpeg.org/' ]);
    disp('  The LiveView may be unactivated, but you can still take pictures.')
  else
    disp([ '  FFMPEG          (https://www.ffmpeg.org/) as "' present '"' ]);
  end
  
end
