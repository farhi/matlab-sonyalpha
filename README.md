# matlab-sonyalpha
Control a Sony Alpha Camera

SONYALPHA A class to control a Sony Alpha Camera (NEX, Alpha, ...) compatible
  with the Camera Remote API by Sony.
 
Usage
-----

```matlab
>> camera = sonyalpha;
```
 
Then you can use the Methods:
- getstatus(camera):  get the camera status
- iso:                set/get ISO setting
- shutter:            set/get shutter speed setting
- mode:               set/get the PASM mode
- timer:              set/get the self timer
- fnumber:            set/get the F/D aperture
- white:              set/get the white balance
- image:              take a shot and display it
- imread:             take a shot and download the image (no display)
 
Connecting the Camera
---------------------
  
  Start your camera and use its Remote Control App (e.g. Play Memories App) 
  from the Camera settings. This starts the JSON REST HTTP server, used to 
  control the camera. The Network SSID is shown on the Camera screen.
  Connect from your PC on that network.
  The usual associated IP is then 192.168.122.1 (port 8080)
 
  The connection must be a dedicated ad-hoc, e.g. can NOT use an intermediate 
  router. If you are already connected to the Internet, you have to drop your
  current connection, or use an additional Wifi adapter (e.g. USB-Wifi).
  
Requirements/Installation
-------------------------

- Matlab, no external toolbox
- A wifi connection
- A Sony Camera
- curl
- ffmpeg (for liveview)

Just copy the files and go into the directory. Then type commands above, once the
camera is configured (see above).
 
Credits
-------

- https://github.com/micolous/gst-plugins-sonyalpha
- https://github.com/Bloodevil/sony_camera_api
 
(c) E. Farhi, GPL2, 2018.








Here are other commenst which I currently use to develop this class (not yet finished)
--------------------------------------------------------------------------------------

You need to start the PlayMemories Remote Control App on the camera. The Camera should be connected using an ad-hoc network, which SSID is shown on the camera screen. The Camera IP will then be:

http://192.168.122.1:8080

Then you can send/receive commands such as:

**getApplicationInfo**: request modes:

- curl -d "{'method': 'getApplicationInfo','params': [],'id': 1,'version': '1.0'}"  http://192.168.122.1:8080/sony/camera; echo ''
- {'result':['Smart Remote Control SR\/4.30 __SAK__','2.1.4'],'id':1}

**getVersions**: get versions:

- curl -d "{'method': 'getVersions','params': [],'id': 1,'version': '1.0'}"  http://192.168.122.1:8080/sony/camera; echo ''
- {'result':[['1.0','1.1','1.2','1.3','1.4']],'id':1}

**getAvailableApiList**:
- curl -d "{'method': 'getAvailableApiList','params': [],'id': 1,'version': '1.0'}"  http://192.168.122.1:8080/sony/camera; echo ''
- {'result':[['getVersions','getMethodTypes','getApplicationInfo','getAvailableApiList','getEvent','startRecMode','stopRecMode']],'id':1}

**startRecMode**: set camera in rec mode (shoot)

- curl -d "{'method': 'startRecMode','params': [],'id': 1,'version': '1.0'}"  http://192.168.122.1:8080/sony/camera; echo ''
- {'result':[0],'id':1}

**livestream**:

- curl -d '{"method": "startLiveview","params": [],"id": 1,"version": "1.0"}'  http://192.168.122.1:8080/sony/camera; echo ''
- http://192.168.122.1:8080/liveview/liveviewstream

**then view livestream with**: https://github.com/micolous/gst-plugins-sonyalpha

- gst-launch-1.0 souphttpsrc location=http://192.168.122.1:8080/liveview/liveviewstream ! sonyalphademux ! jpegparse ! jpegdec ! videoconvert ! autovideosink

**capture a frame** with ffmpeg (takes 2s), can be put into background

- ffmpeg  -ss 1 -i http://192.168.122.1:8080/liveview/liveviewstream -frames:v 1 thumbnail.png
- https://github.com/abarbu/ffmpeg-matlab use Matlab hook, not faster, takes also 2 s but can not be put in background


Requirements
------------

- ffmpeg
- curl



