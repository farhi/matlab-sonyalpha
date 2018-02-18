# matlab-sonyalpha
Control a Sony Alpha Camera

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



