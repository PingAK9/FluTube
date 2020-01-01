import 'package:video_player/video_player.dart';
class CallBackVideoController {
  static CallBackVideoController instance;

  Function(VideoPlayerController videoController) callback;
  Function(bool stateError) listenStateError;

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
  int hashCodeWidget;
  factory StatePlaying() {
    if (instance == null) instance = StatePlaying._internal();
    return instance;
  }
  StatePlaying._internal();
}
enum FlutubeState { ON, OFF } 
enum FlutubeStateScreen { NEW, OLD, SPECIAL} 
class StatePlayer {
  static StatePlayer instance;

  FlutubeState statePlayer;
  FlutubeStateScreen stateScreen;

  factory StatePlayer() {
    if (instance == null) instance = StatePlayer._internal();
    return instance;
  }
  StatePlayer._internal();
}