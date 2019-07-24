function ret=background(self, action)
    % background get an image (background capture)
    % 
    % background(self, 'awaitTakePicture') wait for end of capture (long exposure)
    if nargin < 2, action=''; end
    if isempty(action) && ~strcmp(self.cameraStatus, 'IDLE') % BUSY
      ret='BUSY';
      notify(self, 'busy');
      return
    end
    if isempty(action), action = 'actTakePicture'; end

    if any(strcmp(self.url, {'gphoto2','gphoto', 'usb'}))
      error([ mfilename ': asynchronous capture only available in wifi mode' ])
    else
      url       = fullfile(self.url, 'sony', 'camera');
      self.jsonFile = [ tempname '.json' ];
      self.json     = [];
      json = [ '{"method": "' action '","params": [],"id": 1,"version": "1.0"}' ];
      cmd = [ 'curl -o ' self.jsonFile ' -d ''' json ''' ' url ];
      
      % launch an asynchronous command. Java does not work.
      if ispc
        ret=system([ 'start /b ' cmd ]);
      else
        ret=system([ cmd ' &' ]);
      end
      notify(self, 'busy');
    end
    
  end
