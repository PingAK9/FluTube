import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutube/flutube.dart';
import 'package:flutube/src/callback_control.dart';
import 'package:video_player/video_player.dart';
// import '../video_player_controller.dart';

typedef YoutubeQualityChangeCallback(String quality, Duration position);
typedef ControlsShowingCallback(bool showing);

class ControlsColor {
  final Color timerColor;
  final Color seekBarPlayedColor;
  final Color seekBarUnPlayedColor;
  final Color buttonColor;
  final Color playPauseColor;
  final Color progressBarPlayedColor;
  final Color progressBarBackgroundColor;
  final Color controlsBackgroundColor;

  ControlsColor({
    this.buttonColor = Colors.white,
    this.playPauseColor = Colors.white,
    this.progressBarPlayedColor = Colors.red,
    this.progressBarBackgroundColor = Colors.transparent,
    this.seekBarUnPlayedColor = Colors.grey,
    this.seekBarPlayedColor = Colors.red,
    this.timerColor = Colors.white,
    this.controlsBackgroundColor = Colors.transparent,
  });
}

class Controls extends StatefulWidget {
  final bool showControls;
  final double width;
  final double height;
  final String defaultQuality;
  final bool defaultCall;
  final VoidCallback fullScreenCallback;
  bool isFullScreen;
  final ControlsShowingCallback controlsShowingCallback;
  final bool controlsActiveBackgroundOverlay;
  final Duration controlsTimeOut;
  final bool switchFullScreenOnLongPress;
  final bool hideShareButton;
  PlayControlDelegate playCtrDelegate;
  // VideoPlayerController videoController;

  Controls({
    // this.videoController,
    this.showControls,
    this.height,
    this.width,
    this.defaultCall,
    this.defaultQuality = "720p",
    this.fullScreenCallback,
    this.controlsShowingCallback,
    this.isFullScreen = false,
    this.controlsActiveBackgroundOverlay,
    this.controlsTimeOut,
    this.switchFullScreenOnLongPress,
    this.hideShareButton,
    this.playCtrDelegate,
  });

  @override
  _ControlsState createState() => _ControlsState();
}

class _ControlsState extends State<Controls> {
  bool _showControls;
  double currentPosition = 0;
  String _currentPositionString = "00:00";
  String _remainingString = "- 00:00";
  bool _buffering = false;
  Timer _timer;
  int seekCount = 0;
  bool flagAddListener = false;
  CallBackVideoController callbackController;
  VideoPlayerController videoController;
  @override
  void initState() {
    _showControls = widget.showControls ?? true;
    widget.controlsShowingCallback(_showControls);
    // widget.playCtrDelegate = PlayControlDelegate();
    callbackController = CallBackVideoController();

    callbackController.callback = (_controller) {
      if (_controller?.value?.initialized ?? false) {
        setState(() {
          videoController = _controller;
          if (!flagAddListener && videoController != null) {
            flagAddListener = true;
            videoController.addListener(listener);
          }
        });
      }
    };
    super.initState();

    print("[_ControlsState] initState");
  }

  // @override
  // void didUpdateWidget(Controls oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (videoController != null &&
  //       oldvideoController != null &&
  //       oldvideoController.value.initialized &&
  //       videoController.value.initialized) {
  //     oldvideoController.removeListener(listener);
  //     videoController.addListener(listener);
  //   }
  // }

  // @override
  // void deactivate() {
  //   if (videoController != null &&
  //       videoController.value.initialized) {
  //     videoController.removeListener(listener);
  //   }
  //   super.deactivate();
  // }

  @override
  void dispose() {
    if (!widget.isFullScreen) {
      videoController?.setVolume(0);
    }
    super.dispose();
  }

  listener() {
    if (videoController != null && videoController.value.initialized) {
      // print(" Starting ... ");
      if (videoController.value.position != null &&
          videoController.value.duration != null) {
        if (mounted && videoController.value.isPlaying) {
          setState(() {
            currentPosition = (videoController.value.position.inSeconds ?? 0) /
                videoController.value.duration.inSeconds;
            _buffering = videoController.value.isBuffering;
            _currentPositionString =
                formatDuration(videoController.value.position);
            _remainingString = "- " +
                formatDuration(videoController.value.duration -
                    videoController.value.position);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print("control build");
    return Stack(
      children: <Widget>[
        _showControls
            ? Container(
                // color: Color(0x88000000),
                height: widget.height,
                width: widget.width,
              )
            : Container(),
        GestureDetector(
          onLongPress: () {
            // if (widget.switchFullScreenOnLongPress)
            //   widget.isFullScreen
            //       ? Navigator.pop(context)
            //       : widget.fullScreenCallback();
          },
          onTap: () {
            if (!_buffering) {
              togglePlaying();
            }
          },
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: Duration(milliseconds: 200),
            child: Material(
              color: Color(0x88000000),
              child: Stack(
                children: <Widget>[
                  _buildAppBar(context),
                  Container(
                    width: widget.width - 10,
                    height: widget.height,
                    child: Center(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: _rewind(),
                            flex: 4,
                          ),
                          Expanded(
                            child: _playButton(),
                            flex: 2,
                          ),
                          Expanded(
                            child: _fastForward(),
                            flex: 4,
                          )
                        ],
                      ),
                    ),
                  ),
                  _buildBottomControls(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fastForward() {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: onTapAction,
          onDoubleTap: () {
            if (mounted) {
              if (videoController != null) {
                print("------- double _fastForward -------");
                setState(() {
                  // widget.controlsShowingCallback(_showControls);
                  seekCount += 10;
                });
                videoController.seekTo(
                  Duration(
                      seconds: videoController.value.position.inSeconds + 5),
                );
                Timer(Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      seekCount = 0;
                    });
                  }
                });
              }
            }
          },
          child: Container(
            color: Colors.transparent,
            // width: _width / 2.5,
            // height: _height - 80,
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
//                printLog("Tap _fastForward");
              print("------- tap _fastForward -------");
              if (widget.playCtrDelegate != null) {
                widget.playCtrDelegate.nextVideo();
              }
            },
            child: _showControls
                ? Center(
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.fast_forward,
                        size: 40.0,
                        color: Colors.white,
                      ),
                    ],
                  ))
                : Container(),
          ),
        )
      ],
    );
  }

  Widget _rewind() {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: onTapAction,
          onDoubleTap: () {
            if (mounted) {
              if (videoController != null) {
                print("------- double _rewind -------");
                setState(() {
                  seekCount += 10;
                });
                videoController.seekTo(
                  Duration(
                      seconds: videoController.value.position.inSeconds - 5),
                );
                Timer(Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() {
                      seekCount = 0;
                    });
                  }
                });
              }
            }
          },
          child: Container(
            color: Colors.transparent,
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              print("Tap _rewind");
            },
            child: _showControls
                ? Center(
                    child: GestureDetector(
                    child: Icon(
                      Icons.fast_rewind,
                      size: 40.0,
                      color: Colors.white,
                    ),
                    onTap: () {
                      if (widget.playCtrDelegate != null) {
                        widget.playCtrDelegate.previousVideo();
                      }
                    },
                  ))
                : Container(),
          ),
        )
      ],
    );
  }

  void onTapAction() {
    if (_timer != null) _timer.cancel();
    if (mounted) {
      setState(() {
        _showControls = true;
        widget.controlsShowingCallback(_showControls);
      });
    }
    if (_showControls) {
      _timer = Timer(widget.controlsTimeOut, () {
        if (mounted) {
          setState(() {
            _showControls = false;
            widget.controlsShowingCallback(_showControls);
          });
        }
      });
    }
    // if (!videoController.value.isPlaying) videoController.play();
  }

  Widget _playButton() {
    return IgnorePointer(
      ignoring: !_showControls,
      child: Material(
        borderRadius: BorderRadius.circular(100.0),
        color: Colors.transparent,
        child: GestureDetector(
          // splashColor: Colors.grey[350],
          // borderRadius: BorderRadius.circular(30.0),
          onTap: () {
            onTapAction();
            if (videoController?.value?.initialized ?? false) {
              if (videoController.value.isPlaying) {
                videoController.pause();
              } else {
                videoController.play();
              }
            }
          },
          child: _buffering
              ? CircularProgressIndicator()
              : Icon(
                  (videoController != null &&
                          videoController.value.initialized &&
                          videoController.value.isPlaying)
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40.0,
                ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    int totalLength = 0;

    if (videoController != null && videoController.value.initialized) {
      totalLength = videoController.value.duration.inSeconds;
    }
    // total
    // int totalLength = 20;
    return Positioned(
      bottom: 10.0,
      child: Container(
        color: Colors.transparent,
        width: widget.width,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  _currentPositionString,
                  style: TextStyle(color: Colors.white, fontSize: 12.0),
                ),
              ),
            ),
            Expanded(
              flex: widget.isFullScreen ? 15 :6,
              child: Container(
                padding: EdgeInsets.only(top: 5),
                height: 20,
                child: Slider(
                  activeColor: Colors.red,
                  inactiveColor: Colors.grey,
                  value: currentPosition,
                  onChanged: (position) {
                    if (videoController != null) {
                      togglePlaying();
                      videoController.seekTo(
                        Duration(
                          seconds: (position * totalLength).floor(),
                        ),
                      );
                      videoController.play();
                      if (mounted) {
                        setState(() {
                          currentPosition = position;
                        });
                      }
                    }
                  },
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _remainingString,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: InkWell(
                splashColor: Colors.grey[350],
                onTap: () {
                  if (widget.playCtrDelegate != null) {
                    bool _isFull =
                        widget.playCtrDelegate.fullscreen(widget.isFullScreen);

                    setState(() {
                      widget.isFullScreen = _isFull;
                    });
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(widget.width <= 200 ? 4.0 : 10.0),
                  child: Icon(
                    widget.isFullScreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                        size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void togglePlaying() {
    // if (videoController!= null && widget.playCtrDelegate != null) {
    //   widget.playCtrDelegate.playVideo(videoController.value.isPlaying);
    // }
    if (videoController != null && videoController.value.initialized) {
      if (videoController.value.isPlaying == true) {
        videoController.pause();
        if (mounted) {
          setState(() {
            _showControls = true;
            widget.controlsShowingCallback(_showControls);
          });
        }
      } else {
        videoController.play();
      }
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () {
                if (widget.playCtrDelegate != null) {
                  widget.playCtrDelegate.backButton();
                }
              },
              child: Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    IconButton(
                        iconSize: 30,
                        icon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        )),
                    Text(
                      'Detail',
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16.5),
                    )
                  ],
                ),
              ),
            )),
        // _buildSubtitles(context)
      ],
    );
  }

//  void shareVideo() {
//    final RenderBox box = context.findRenderObject();
//    Share.share("https://youtu.be/${widget.videoId}",
//        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
//  }

  String formatDuration(Duration position) {
    final ms = position.inMilliseconds;
    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    var minutes = seconds ~/ 60;
    seconds = seconds % 60;
    final hoursString = hours >= 10 ? '$hours' : hours == 0 ? '00' : '0$hours';
    final minutesString =
        minutes >= 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';
    final secondsString =
        seconds >= 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';
    final formattedTime =
        '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';
    return formattedTime;
  }
}
