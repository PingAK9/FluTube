import 'dart:async';

abstract class PlayControlDelegate {
  void nextVideo ();
  void previousVideo ();
  bool playVideo (bool isLive);
  Future<bool> fullscreen (bool isFullscreen);
  bool subvideo (bool isShowSub);
  void backButton ();
  Function() replay;
  bool showControl (bool isShow);
}
