import 'dart:async';

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
      this.isFullscreen})
      : super(key: key) {
    this._videourls = "https://www.youtube.com/watch?v=" + videourl;
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
      this.isFullscreen})
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
      if (this.videoController != null) {
        disposeController("initState");
      }
      if (chewieController != null) {
        chewieController.dispose();
      }
    } catch (e) {}
    callBackVideoController = CallBackVideoController();
    statePlaying = StatePlaying();
    player = StatePlayer();
    _needsShowThumb = !widget.autoPlay;
    if (_isPlaylist) {
      _initialize((widget._videourls
          as List<String>)[0]); // Play the very first video of the playlist
    } else {
      _initialize(widget._videourls as String);
      statePlaying.idPlaying = widget._idVideo;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (videoController != null && player.statePlayer == FlutubeState.OFF) {
      this.videoController.removeListener(_playingListener);
      this.videoController.removeListener(_errorListener);
      this.videoController.removeListener(_endListener);
      this.videoController.removeListener(_startListener);
    }

    print(" what is dispose flutube!");
    super.dispose();
  }

  disposeController(String func_name) {
    try {
      if (this.videoController != null &&
          statePlaying.idPlaying != null &&
          statePlaying.idPlaying != widget._idVideo) {
        this.videoController.removeListener(_playingListener);
        this.videoController.removeListener(_errorListener);
        this.videoController.removeListener(_endListener);
        this.videoController.removeListener(_startListener);
        // this.videoController.dispose();
      }
    } catch (e) {}
  }

  void _initialize(String _url) {
    // print("_url $_url");
    
    _fetchVideoURL(_url).then((url) {
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
        looping: _isPlaylist ? false : widget.looping,
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
    if (((player.statePlayer == FlutubeState.OFF) ||
        (statePlaying.idPlaying != null && statePlaying.idPlaying != widget._idVideo)) && 
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
      if (this.videoController.value.initialized &&
          !this.videoController.value.isBuffering) {
        if (this.videoController.value.position >=
            this.videoController.value.duration) {
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
            if (_currentlyPlaying <
                (widget._videourls as List<String>).length - 1) {
              _playlistLoadNext();
            } else {
              if (widget.looping) {
                _playlistLoop();
              }
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
    if (statePlaying.idPlaying == widget._idVideo &&
        player.statePlayer == FlutubeState.ON) {
      print("--------------------- ERROR ----------------------");
      Timer(Duration(seconds: 3), () {
        if (mounted) {
          _initialize(widget._videourls as String);
        }
      });
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
    _initialize((widget._videourls as List<String>)[_currentlyPlaying]);
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
    _initialize((widget._videourls as List<String>)[0]);
    chewieController.play();
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
                Image.network(
                  _videoThumbURL(_isPlaylist
                      ? widget._videourls[_currentlyPlaying]
                      : widget._videourls),
                  fit: BoxFit.cover,
                ),
                Center(
                  child: ClipOval(
                    child: Container(
                      color: Colors.white,
                      child: IconButton(
                        iconSize: 50.0,
                        color: Colors.black,
                        icon: Icon(
                          Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              this.videoController.play();
                              _needsShowThumb = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Controls _controls = Controls(
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

  Future<String> _fetchVideoURL(String yt) async {
    print("-------------------------------------- FETCH VIDEO -----------------------------------");
    final response = await http.get(yt);
    Iterable parseAll = _allStringMatches(
        response.body, RegExp("\"url_encoded_fmt_stream_map\":\"([^\"]*)\""));
    final Iterable<String> parse =
        _allStringMatches(parseAll.toList()[0], RegExp("url=(.*)"));

    final List<String> urls = parse.toList()[0].split('url=');
    parseAll = _allStringMatches(urls[1], RegExp("([^&,]*)[&,]"));
    if (parseAll.isEmpty) parseAll = [urls[1]];

    String finalUrl = Uri.decodeFull(parseAll.toList()[0]);
    if (finalUrl.indexOf('\\u00') > -1)
      finalUrl = finalUrl.substring(0, finalUrl.indexOf('\\u00'));
print("-------------------------------------- FETCH DONE -----------------------------------");
    return finalUrl;
  }

  Iterable<String> _allStringMatches(String text, RegExp regExp) =>
      regExp.allMatches(text).map((m) => m.group(0));

  String _videoThumbURL(String yt) {
    String id = yt.substring(yt.indexOf('v=') + 2);
    if (id.contains('&')) id = id.substring(0, id.indexOf('&'));
    return "http://img.youtube.com/vi/$id/0.jpg";
  }
}
