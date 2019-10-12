import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import 'package:flutube/src/play_control_delegate.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import 'callback_control.dart';
import 'control.dart';
import 'control_color.dart';

typedef FTCallBack(VideoPlayerController controller);

class FluTube extends StatefulWidget {
  /// Youtube video URL(s)
  var _videourls;

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

  FluTube(
    @required String videourl, {
    Key key,
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
    this.isFullscreen
  }) : super(key: key) {
    this._videourls = videourl;
  }

  FluTube.playlist(
    @required List<String> playlist, {
    Key key,
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
    this.isFullscreen
  }) : super(key: key) {
    assert(playlist.length > 0, 'Playlist should not be empty!');
    this._videourls = playlist;
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

  @override
  initState() {
    callBackVideoController = CallBackVideoController();
    super.initState();
    if (videoController != null) videoController.dispose();
    if (chewieController != null) chewieController.dispose();
//    controls = Controls();
    _needsShowThumb = !widget.autoPlay;

    if (_isPlaylist) {
      _initialize((widget._videourls
          as List<String>)[0]); // Play the very first video of the playlist
    } else {
      _initialize(widget._videourls as String);
    }
  }

  @override
  void dispose() {
    if (videoController != null) videoController.dispose();
    if (chewieController != null) chewieController.dispose();
    widget.callBackController(videoController);
    callBackVideoController.callback(videoController);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initialize(String _url) {
    _lastUrl = _url;
    print("_url $_url");
    _fetchVideoURL(_url).then((url) {
      videoController = VideoPlayerController.network(url)
        ..addListener(_playingListener)
        ..addListener(_errorListener)
        ..addListener(_endListener)
        ..addListener(_startListener);

      // Video start callback
      // if (widget.onVideoStart != null) {
      //   videoController.addListener(_startListener);
      // }
      chewieController = ChewieController(
          videoPlayerController: videoController,
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

      setState(() {
        showControl = false;
      });
      widget.callBackController(videoController);
      callBackVideoController.callback(videoController);
    });
  }

  _playingListener() {
    if (isPlaying != videoController.value.isPlaying) {
      setState(() {
        isPlaying = videoController.value.isPlaying;
        widget.callBackController(videoController);
        callBackVideoController.callback(videoController);
      });
    }
  }

  _startListener() {
    if (videoController.value.initialized && isPlaying) {
      callBackVideoController.callback(videoController);
      widget.callBackController(videoController);
      setState(() {
        // _showVideoProgressBar = !showing;
      });
    }
  }

  _endListener() {
    // Video end callback
    if (videoController != null) {
      if (videoController.value.initialized &&
          !videoController.value.isBuffering) {
        if (videoController.value.position >= videoController.value.duration) {
          if (isPlaying) {
            chewieController.pause();
            chewieController.seekTo(Duration());
          }
          if (widget.onVideoEnd != null) widget.onVideoEnd();
          if (widget.showThumb && !_isPlaylist) {
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
          widget.callBackController(videoController);
          callBackVideoController.callback(videoController);
        }
      }
    }
  }

  _errorListener() {
    if (!videoController.value.hasError) return;
    print("_errorListener $_lastUrl");
//    if (videoController.value.errorDescription.contains("code: 403"))
//      _initialize(_lastUrl);
    _initialize(_lastUrl);
  }

  _playlistLoadNext() {
    chewieController?.dispose();
    setState(() {
      _currentlyPlaying++;
    });
    videoController.pause();
    videoController = null;
    _initialize((widget._videourls as List<String>)[_currentlyPlaying]);
    chewieController.play();
    widget.callBackController(videoController);
    callBackVideoController.callback(videoController);
  }

  _playlistLoop() {
    chewieController?.dispose();
    setState(() {
      _currentlyPlaying = 0;
    });
    videoController.pause();
    videoController = null;
    _initialize((widget._videourls as List<String>)[0]);
    chewieController.play();
    widget.callBackController(videoController);
    callBackVideoController.callback(videoController);
  }

  @override
  Widget build(BuildContext context) {
    print(_currentlyPlaying);
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
                          setState(() {
                            videoController.play();
                            _needsShowThumb = false;
                          });
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
        showControls: false,
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
      return chewieController != null
          ? Stack(
              children: <Widget>[
                Chewie(
                  key: widget.key,
                  controller: chewieController,
                  streamSubWidget: widget.subVideo,
                ),
                _controls ?? Container()
              ],
            )
          : AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
    }
  }

  Future<String> _fetchVideoURL(String yt) async {
    final response = await http.get(yt);
    Iterable parseAll = _allStringMatches(
        response.body, RegExp("\"url_encoded_fmt_stream_map\":\"([^\"]*)\""));
        
    final Iterable<String> parse =
        _allStringMatches(parseAll.toList()[0], RegExp("url=(.*)"));
    final List<String> urls = parse.toList()[0].split('url=');
    parseAll = _allStringMatches(urls[1], RegExp("([^&,]*)[&,]"));
    String finalUrl = Uri.decodeFull(parseAll.toList()[0]);
    if (finalUrl.indexOf('\\u00') > -1)
      finalUrl = finalUrl.substring(0, finalUrl.indexOf('\\u00'));
    return finalUrl;
  }

  Iterable<String> _allStringMatches(String text, RegExp regExp) =>
      regExp.allMatches(text).map((m) => m.group(0));

  String _videoThumbURL(String yt) {
    String id = yt.substring(yt.indexOf('v=') + 2);
    if (id.contains('&')) id = id.substring(0, id.indexOf('&'));
    return "http://img.youtube.com/vi/$id/0.jpg";
  }

  Widget initControls() {
//    print("initControls");
    return Controls(
      height: heightCurrent,
      width: widthCurrent,
      // controller: videoController,
      showControls: true,
      isFullScreen: _isFullScreen,
      controlsActiveBackgroundOverlay: false,
      // controlsColor: ControlsColor(),
      controlsTimeOut: const Duration(seconds: 2),
      switchFullScreenOnLongPress: false,
      controlsShowingCallback: (showing) {
        print("showing $showing");
        Timer(Duration(milliseconds: 600), () {
          if (mounted)
            setState(() {
//               _showVideoProgressBar = !showing;
            });
        });
      },
      fullScreenCallback: () async {
        // await _pushFullScreenWidget(context);
      },
      // hideShareButton: widget.hideShareButton,
    );
  }
}
