import '../core/controllers/screen_controller.dart';

class ShellController extends ScreenController {
  int selected = 0;
  int generation = 0;
}

class AppController extends ScreenController {
  bool ready = false;
  void finishSplash() => change(() => ready = true);
}
