# matlab-sonyalpha
Control a Sony Alpha Camera

![Image of A6000](https://github.com/farhi/matlab-sonyalpha/blob/master/doc/A6000.png)

SONYALPHA: A class to control a Sony Alpha Camera (NEX, Alpha, ...) compatible
  with the Camera Remote API by Sony.
 
Usage
-----

```matlab
>> camera = sonyalpha;
>> plot(camera)
>> capture(camera)
```

The LiveView image, that is shown with the "plot" method, is updated continuously, and is rather slow (e.g. every 2s).
 
Connecting the Camera
---------------------
  
  Start your camera and use its Remote Control App (e.g. Play Memories App) 
  from the Camera settings. This starts the JSON REST HTTP server, used to 
  control the camera. The Network SSID is shown on the Camera screen.
  Connect from your PC on that network.
  The usual associated IP is then 192.168.122.1 (port 8080)
 
  The connection must be a dedicated ad-hoc, e.g. can _NOT_ use an intermediate 
  router. If you are already connected to the Internet, you have to drop your
  current connection, or use an additional Wifi adapter (e.g. USB-Wifi).
  
  If you need to specify the camera IP, use:
  
```matlab
>> camera = sonyalpha('http://192.168.122.1:8080');
```
  
Using the Plot Window
---------------------

![Image of SonyAlpha](https://github.com/farhi/matlab-sonyalpha/blob/master/doc/SonyAlpha_image.png)

  The Plot window is shown when shooting still images or updating the LiveView. It
  contains the File, View, Settings and Shoot menus. It also shows the main
  settings, as well as a focus quality measure (higher is better).

  The View menu allows to add Pointers and Marks on top of the current image. These
  can be used for e.g. alignment. You can equally add Pointers directly
  right-clicking on the image.

  The Settings menu allows to change the most important camera settings, including
  the zoom level (when available). 

  The Shoot menu allows to take a single picture, update the live view (lower 
  resolution), as well as start a continuous or timelapse shooting. 
  To stop the continuous/timelapse session, select the Shoot item again.
  
Methods
-------

- about         Display camera settings in a dialogue window.   
- addlistener   Add listener for event.   
- api           Call the camera API with method.   
- capture       Capture an image with current camera settings (in background).   
- char          Returns a string that gathers main camera settings.   
- close         Delete the SonyAlpha connection and its timer.   
- continuous    Take pictures continuously.   
- curl          Prepare curl command.   
- delete        Delete a handle object.   
- disp          Display SonyAlpha object (details).   
- display       Display SonyAlpha object (short).  
- exp           Get/set the Exposure Compensation.   
- findobj       Find objects matching specified conditions.   
- findprop      Find property of MATLAB handle object.   
- fnumber       Get/set the F/D number (apperture) setting (A mode).   
- focus         Get/set the focus mode.   
- get_state     Return the camera state, e.g. BUSY, IDLE.   
- getstatus     Get the Camera status and all settings.  
- help          Open the Help page (web browser).   
- image         Take a picture, and display it.   
- imread        Take a picture, read it as an RGB matrix, and delete any local file.   
- iso           Get/set the ISO setting as a string (can be 'AUTO'). 
- isvalid       Test handle validity.   
- lastImageFile Return the last image file name (or URL).   
- mode          Get/set the shooting Mode (e.g. PASM).   
- notify        Notify listeners of event.   
- plot          Get a live-view image, display it, but does not store it.   
- quality       Get/set the image quality.   
- shutter       Get/set the shutter speed setting (S mode).   
- start         Set the camera into shooting mode.   
- stop          Stop the camera shooting.   
- timelapse     Take pictures with current settings every 'wait' seconds.   
- timer         Get/set the self Timer setting.   
- urlread       Take a picture and return the distant URL (no upload).   
- urlwrite      Take a picture, and download it as a local file.   
- waitfor       Wait for the camera to be idle.   
- white         Get/set the white balance setting.   
- zoom          Get/set the zoom value. 
  
Requirements/Installation
-------------------------

- Matlab, no external toolbox
- A wifi connection
- A Sony Camera
- curl (for wifi connection). Get it at https://curl.haxx.se/
- ffmpeg (for liveview with Wifi). Get it at https://www.ffmpeg.org/

Just copy the files and go into the directory. Then type commands above, once the
camera is configured (see above).

The list of officially supported Sony cameras is: 
- Alpha 7, R 7S, 7RII, 7SII, 5000, 5100, 6000, 6300, 6500, 
- NEX   5R, 5T, 6

You may alternatively control the camera via a USB connection with the GPhoto2
interface from https://github.com/farhi/matlab-gphoto
 
Credits
-------

- https://github.com/micolous/gst-plugins-sonyalpha
- https://github.com/Bloodevil/sony_camera_api
- https://developer.sony.com/develop/cameras/#overview-content
- https://developer.sony.com/file/download/sony-camera-remote-api-beta-sdk-2/
 
(c) E. Farhi, GPL2, 2018.




