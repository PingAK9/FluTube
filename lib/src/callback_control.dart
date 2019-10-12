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