import 'package:video_player/video_player.dart';
class CallBackVideoController {
  static CallBackVideoController instance;

  Function(VideoPlayerController videoController) callback;

  factory CallBackVideoController() {
    if (instance == null) instance = CallBackVideoController._internal();
    return instance;
  }
  CallBackVideoController._internal();
}
class EventControl {
  static EventControl instance;

  Function() play;

  factory EventControl() {
    if (instance == null) instance = EventControl._internal();
    return instance;
  }
  EventControl._internal();
}

class StatePlaying {
  static StatePlaying instance;

  String idPlaying;

  factory StatePlaying() {
    if (instance == null) instance = StatePlaying._internal();
    return instance;
  }
  StatePlaying._internal();
}
enum FlutubeState { ON, OFF } 
class StatePlayer {
  static StatePlayer instance;

  FlutubeState statePlayer;

  factory StatePlayer() {
    if (instance == null) instance = StatePlayer._internal();
    return instance;
  }
  StatePlayer._internal();
}