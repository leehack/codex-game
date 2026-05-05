import 'sound_stub.dart' if (dart.library.js_interop) 'sound_web.dart' as impl;

enum SoundCue {
  click,
  start,
  question,
  answer,
  correct,
  wrong,
  damage,
  victory,
  defeat,
}

class SoundController {
  bool enabled = true;

  void play(SoundCue cue) {
    if (!enabled) {
      return;
    }
    impl.playCue(cue.name);
  }
}
