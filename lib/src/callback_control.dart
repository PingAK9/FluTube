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