import 'dart:js_interop';

@JS('codexSound')
external void _codexSound(JSString cue);

void playCue(String cue) {
  try {
    _codexSound(cue.toJS);
  } on Object {
    // Browser audio can be unavailable before the first user gesture.
  }
}
