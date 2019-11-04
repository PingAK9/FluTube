import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:flutube/src/play_control_delegate.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'callback_control.dart';
import 'control.dart';

typedef FTCallBack(VideoPlayerController controller);

class FluTube extends StatefulWidget {
  /// Youtube video URL(s)
  var _videourls;

  var _idVideo;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Whether or not to show the controls
  final bool showControls;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// Allow screen to sleep
  final bool allowScreenSleep;

  /// Show mute icon
  final bool allowMuting;

  /// Show fullscreen button.
  final bool allowFullScreen;

  /// Device orientation when leaving fullscreen.
  final List<DeviceOrientation> deviceOrientationAfterFullscreen;

  /// System overlays when exiting fullscreen.
  final List<SystemUiOverlay> systemOverlaysAfterFullscreen;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// Play video directly in fullscreen
  final bool fullscreenByDefault;

  /// Whether or not to show the video thumbnail when the video did not start playing.
  final bool showThumb;

  final Widget subVideo;

  /// Video events

  /// Video start
  final VoidCallback onVideoStart;

  /// Video end
  final VoidCallback onVideoEnd;

  final Widget customControl;

  final double width;

  final double height;

  FTCallBack callBackController;

  PlayControlDelegate playCtrDelegate;

  bool isFullscreen;

  String typeVideo;

  String urlImageThumnail;

  FluTube(@required String videourl,
      {Key key,
      this.aspectRatio,
      this.autoInitialize = false,
      this.autoPlay = false,
      this.startAt,
      this.looping = false,
      this.placeholder,
      this.showControls = true,
      this.fullscreenByDefault = false,
      this.showThumb = true,
      this.allowMuting = true,
      this.allowScreenSleep = false,
      this.allowFullScreen = true,
      this.deviceOrientationAfterFullscreen,
      this.systemOverlaysAfterFullscreen,
      this.onVideoStart,
      this.onVideoEnd,
      this.callBackController,
      this.subVideo,
      this.customControl,
      this.width,
      this.height,
      this.playCtrDelegate,
      this.isFullscreen,
      this.typeVideo = "YOUTUBE",
      this.urlImageThumnail,
    })
      : super(key: key) {
    this._videourls = videourl; //TODO: data cu chua xu ly lai.
    this._idVideo = videourl;
  }

  FluTube.playlist(@required List<String> playlist,
      {Key key,
      this.aspectRatio,
      this.autoInitialize = false,
      this.autoPlay = false,
      this.startAt,
      this.placeholder,
      this.looping = false,
      this.showControls = true,
      this.fullscreenByDefault = false,
      this.showThumb = true,
      this.allowMuting = true,
      this.allowScreenSleep = false,
      this.allowFullScreen = true,
      this.deviceOrientationAfterFullscreen,
      this.systemOverlaysAfterFullscreen,
      this.onVideoStart,
      this.onVideoEnd,
      this.callBackController,
      this.subVideo,
      this.customControl,
      this.width,
      this.height,
      this.playCtrDelegate,
      this.isFullscreen,
      this.typeVideo = "YOUTUBE"})
      : super(key: key) {
    assert(playlist.length > 0, 'Playlist should not be empty!');
    this._videourls = playlist;
    this._idVideo = "";
  }

  @override
  FluTubeState createState() => FluTubeState();
}

class FluTubeState extends State<FluTube> with WidgetsBindingObserver {
  VideoPlayerController videoController;
  ChewieController chewieController;
  bool isPlaying = false;
  bool _needsShowThumb;
  int _currentlyPlaying = 0; // Track position of currently playing video
  double widthCurrent;
  double heightCurrent;
  String _lastUrl;
  bool get _isPlaylist => widget._videourls is List<String>;
  bool _isFullScreen = false;
  Controls controls;
  bool showControl = false;
  CallBackVideoController callBackVideoController;
  StatePlaying statePlaying;
  StatePlayer player;
  @override
  initState() {
    super.initState();
    try {
      if (this.videoController != null || chewieController != null) {
        disposeController();
      }
    } catch (e) {}  
    callBackVideoController = CallBackVideoController();
    statePlaying = StatePlaying();
    player = StatePlayer();
    _needsShowThumb = !widget.autoPlay;
    if (_isPlaylist) {
      _initialize((widget._videourls as List<String>)[0], widget.typeVideo); // Play the very first video of the playlist
    } else {
      _initialize(widget._videourls as String, widget.typeVideo);
    }
    widget.playCtrDelegate.replay = (){
      _playVideoLoop();
    };
  }

  @override
  void dispose() {
    print("[flutube_player.dart]-------------dispose-------------");
    WidgetsBinding.instance.removeObserver(this);
    if (videoController != null && player.statePlayer == FlutubeState.OFF) {
      this.videoController.removeListener(_playingListener);
      this.videoController.removeListener(_errorListener);
      this.videoController.removeListener(_endListener);
      this.videoController.removeListener(_startListener);
    }
    if(this.chewieController != null){
      if(this.chewieController.videoPlayerController.value.isPlaying){
        this.chewieController.videoPlayerController.pause();
      }
      this.chewieController.dispose();
    }
    super.dispose();
  }

  disposeController() {
    try {
      if (this.videoController != null && statePlaying.hashCodeWidget != null && statePlaying.hashCodeWidget != widget.playCtrDelegate.hashCode) {
        this.videoController.removeListener(_playingListener);
        this.videoController.removeListener(_errorListener);
        this.videoController.removeListener(_endListener);
        this.videoController.removeListener(_startListener);
      }
      if(this.chewieController != null){
        if(this.chewieController.videoPlayerController.value.isPlaying){
          this.chewieController.videoPlayerController.pause();
        }
        this.chewieController.dispose();
      }
    } catch (e) {}
  }

  void _initialize(String _url, String type) {
    print("[Flutube_player.dart] _initialize--------------------URL VIDEO: $_url");
    statePlaying.hashCodeWidget = widget.playCtrDelegate.hashCode;
    _fetchVideoURL(_url, type).then((url) {
      this.videoController = VideoPlayerController.network(url)
        ..addListener(_playingListener)
        ..addListener(_errorListener)
        ..addListener(_endListener)
        ..addListener(_startListener);
      chewieController = ChewieController(
        videoPlayerController: this.videoController,
        aspectRatio: widget.aspectRatio,
        autoInitialize: widget.autoInitialize,
        autoPlay: widget.autoPlay,
        startAt: widget.startAt,
        looping: false,
        placeholder: widget.placeholder,
        showControls: false,
        fullScreenByDefault: widget.fullscreenByDefault,
        allowFullScreen: widget.allowFullScreen,
        deviceOrientationsAfterFullScreen:
            widget.deviceOrientationAfterFullscreen,
        systemOverlaysAfterFullScreen: widget.systemOverlaysAfterFullscreen,
        allowedScreenSleep: widget.allowScreenSleep,
        allowMuting: widget.allowMuting,
      );

      if (this.videoController != null &&
          this.videoController.value.initialized) {
        print("---------------------call back from init to CONTROL------------------");
        callBackVideoController.callback(this.videoController);
        widget.callBackController(this.videoController);
      }
    });
  }

  _playingListener() {
    if (isPlaying != this.videoController.value.isPlaying && mounted) {
      setState(() {
        isPlaying = this.videoController.value.isPlaying;
      });
    }
  }

  _startListener() {
    // TODO: check listen - handle next and pre of player -- 02/11/2019
    // print("---------------------call back from _startListener to CONTROL xxx------------------");
    // print(player.statePlayer == FlutubeState.OFF);
    // print(statePlaying.idPlaying != null);
    // print(statePlaying.idPlaying != widget._idVideo);
    // print(this.videoController != null);
    // print(this.videoController.value.isPlaying);

    if (((player.statePlayer == FlutubeState.OFF) ||
        (statePlaying.hashCodeWidget != null && statePlaying.hashCodeWidget != widget.playCtrDelegate.hashCode)) && 
        this.videoController != null && this.videoController.value.isPlaying ) {
      this.videoController.pause();
    }
    if (this.videoController != null && this.videoController.value.initialized && mounted) {
      callBackVideoController.callback(this.videoController);
      widget.callBackController(this.videoController);
    }
  }

  _endListener() {
    if (this.videoController != null) {
      if (this.videoController.value.initialized && !this.videoController.value.isBuffering) {
        if (this.videoController.value.position >= this.videoController.value.duration) {
          if (isPlaying) {
            chewieController.pause();
            chewieController.seekTo(Duration());
          }
          if (widget.onVideoEnd != null) widget.onVideoEnd();
          if (widget.showThumb && !_isPlaylist && mounted) {
            setState(() {
              _needsShowThumb = true;
            });
          }
          if (_isPlaylist) {
            if (_currentlyPlaying < (widget._videourls as List<String>).length - 1) {
              _playlistLoadNext();
            } else {
              if (widget.looping) {
                _playlistLoop();
              }
            }
          }else{
            if(widget.looping) {
              _playVideoLoop();
            }
          }
          
          widget.callBackController(this.videoController);
          callBackVideoController.callback(this.videoController);
        }
      }
    }
  }

  _errorListener() {
    if (!this.videoController.value.hasError) return;
    // TODO: check _errorListener - handle next and pre of player -- 02/11/2019
    // print("--------------------- ERROR  2 ----------------------");
    // print(statePlaying.idPlaying);
    // print(widget._idVideo);
    // print(player.statePlayer == FlutubeState.ON);
    if (statePlaying.hashCodeWidget == widget.playCtrDelegate.hashCode && player.statePlayer == FlutubeState.ON) {
      _initialize(widget._videourls as String, widget.typeVideo);
    }
  }

  _playlistLoadNext() {
    chewieController?.dispose();
    if (mounted) {
      setState(() {
        _currentlyPlaying++;
      });
    }
    this.videoController.pause();
    this.videoController = null;
    _initialize((widget._videourls as List<String>)[_currentlyPlaying], widget.typeVideo);
    chewieController.play();
  }

  _playlistLoop() {
    chewieController?.dispose();
    if (mounted) {
      setState(() {
        _currentlyPlaying = 0;
      });
    }
    this.videoController.pause();
    this.videoController = null;
    _initialize((widget._videourls as List<String>)[0], widget.typeVideo);
    chewieController.play();
  }
  _playVideoLoop() {
    print("-------------------Handle current-----------------");
     setState(() {
      chewieController?.dispose();
      this.videoController.pause();
      this.videoController = null;
      _initialize(widget._videourls as String, widget.typeVideo);
      });
    
  }


  @override
  Widget build(BuildContext context) {
    if (widget.showThumb && !isPlaying && _needsShowThumb) {
      return Center(
        child: Container(
          width: MediaQuery.of(context).size.width,
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CachedNetworkImage(
                  imageUrl: widget.urlImageThumnail ?? "http://i3.ytimg.com/vi/D86RtevtfrA/hqdefault.jpg",
                  width: widget.width,
                  height: widget.height,
                  fit: BoxFit.cover,
                )
              ],
            ),
          ),
        ),
      );
    } else {
      Controls _controls = Controls(
        urlImageThumnail: widget.urlImageThumnail,
        playCtrDelegate: widget.playCtrDelegate,
        width: widget.width,
        height: widget.height,
        showControls: true,
        isFullScreen: widget.isFullscreen,
        controlsActiveBackgroundOverlay: false,
        controlsTimeOut: const Duration(seconds: 2),
        switchFullScreenOnLongPress: false,
        controlsShowingCallback: (showing) {
          Timer(Duration(milliseconds: 600), () {
            // if (mounted)
            //   setState(() {
            //     showControl = showing;
            //     // _showVideoProgressBar = !showing;
            //   });
          });
        },
        fullScreenCallback: () async {
          // await _pushFullScreenWidget(context);
        },
        // hideShareButton: widget.hideShareButton,
      );
      return Stack(
        children: <Widget>[
          chewieController != null
              ? Chewie(
                  key: widget.key,
                  controller: chewieController,
                  streamSubWidget: widget.subVideo,
                )
              : Container(),
          _controls
        ],
      );
    }
  }

  Future<String> _fetchVideoURL(String yt, String type) async {
    if(type.toUpperCase() == "MP4") return yt;
    if(type.toUpperCase() == "YOUTUBE") { yt = "https://www.youtube.com/watch?v=" + yt;}
    // print("-------------------------------------- FETCH VIDEO -----------------------------------");
    final response = await http.get(yt);

    // print("========================response.body========================");
    // print(response.body);

    Iterable parseAll = _allStringMatches(
        response.body, RegExp("\"url_encoded_fmt_stream_map\":\"([^\"]*)\""));

    // print("========================parseAll 1========================");
    // printWrapped(parseAll.toString());

    final Iterable<String> parse =
        _allStringMatches(parseAll.toList()[0], RegExp("url=(.*)"));

    // print("========================parse========================");
    // printWrapped(parse.toString());

    final List<String> urls = parse.toList()[0].split('url=');

    // print("========================urls========================");
    // printWrapped(urls.toString());


    parseAll = _allStringMatches(urls[1], RegExp("([^&,]*)[&,]"));

    // print("========================parseAll 2========================");
    // print(parseAll);

    if (parseAll.isEmpty) parseAll = [urls[1]];

    // print("========================parseAll 2.1========================");
    // printWrapped(parseAll.toString());

    String finalUrl = Uri.decodeFull(parseAll.toList()[0]);

    // print("========================finalUrl========================");
    // printWrapped(finalUrl);


    if (finalUrl.indexOf('\\u00') > -1)
      finalUrl = finalUrl.substring(0, finalUrl.indexOf('\\u00'));


    // print("========================finalUrl 1.1========================");
    // printWrapped(finalUrl);

// print("-------------------------------------- FETCH DONE -----------------------------------");
    return finalUrl;
  }

  Iterable<String> _allStringMatches(String text, RegExp regExp) =>
      regExp.allMatches(text).map((m) => m.group(0));

  String _videoThumbURL(String yt) {
    String id = yt.substring(yt.indexOf('v=') + 2);
    if (id.contains('&')) id = id.substring(0, id.indexOf('&'));
    return "http://img.youtube.com/vi/$id/0.jpg";
  }
  void printWrapped(String text) {
    final pattern = new RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => print(match.group(0)));
  }
}
