# matlab-sonyalpha
Control a Sony Alpha Camera

![Image of A6000](https://github.com/farhi/matlab-sonyalpha/blob/master/doc/A6000.png)

SONYALPHA: A class to control a Sony Alpha Camera (NEX, Alpha, ...) compatible
  with the Camera Remote API by Sony.
 
Usage
-----

```matlab
>> camera = sonyalpha;
```
 
Then you can use the Methods:

- getstatus:          get the camera status
- start:              set the camera ready for shooting pictures
- stop:               stop the shooting mode
- iso:                set/get ISO setting
- shutter:            set/get shutter speed setting
- mode:               set/get the PASM mode
- timer:              set/get the self timer
- fnumber:            set/get the F/D aperture
- white:              set/get the white balance
- exp:                set/get the exposure compensation
- focus:              set/get the focus mode
- zoom:               zoom in or out
- urlread:            take a picture and return the distant URL (no download)
- imread:             take a picture and download the RGB image (no display)
- image:              take a picture and display it
- plot:               show the live-view image (not stored)
- continuous:         start/stop continuous shooting with current settings.
- timelapse:          start/stop timelapse  shooting with current settings.

as well as other methods that you can list with:
```matlab
>> methods(camera)
```

The LiveView image, that is shown with the "plot" method, is _NOT_ updated continuously, and is rather slow (e.g. 2s).
 
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
  
Using the Plot Window
---------------------

![Image of SonyAlpha](https://github.com/farhi/matlab-sonyalpha/blob/master/doc/SonyAlpha_image.png)

  The Plot window is shown when shooting stil images or updating the LiveView. It
  contains the File, View, Settings and Shoot menus.

  The View menu allows to add Pointers and Marks on top of the current image. These
  can be used for e.g. alignment. You can equally add Pointers directly
  right-clicking on the image.

  The Settings menu allows to change the most important camera settings, including
  the zoom level (when available). 

  The Shoot menu allows to take a single picture, update the live view (lower 
  resolution), as well as start a continuous or timelapse shooting. 
  To stop the continuous/timelapse session, select the Shoot item again.
  
Requirements/Installation
-------------------------

- Matlab, no external toolbox
- A wifi connection
- A Sony Camera
- curl: Get it at https://curl.haxx.se/
- ffmpeg (for liveview): Get it at https://www.ffmpeg.org/

Just copy the files and go into the directory. Then type commands above, once the
camera is configured (see above).
 
Credits
-------

- https://github.com/micolous/gst-plugins-sonyalpha
- https://github.com/Bloodevil/sony_camera_api
- https://developer.sony.com/develop/cameras/#overview-content
 
(c) E. Farhi, GPL2, 2018.




