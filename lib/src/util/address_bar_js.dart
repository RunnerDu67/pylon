import 'dart:js_interop';

@JS('window')
@staticInterop
external _JSWindow get _window;

@JS()
@staticInterop
class _JSWindow {}

@JS()
@staticInterop
class _JSLocation {}

@JS()
@staticInterop
class _JSHistory {}

@JS()
@staticInterop
class JSObject {}

extension _JSWindowExtension on _JSWindow {
  external _JSLocation get location;
  external _JSHistory get history;
}

extension _JSLocationExtension on _JSLocation {
  external String get href;
}

extension _JSHistoryExtension on _JSHistory {
  external void pushState(JSObject? data, String title, String? url);
}

String get $hrefPylon => _window.location.href;

void $pushHrefPylon(JSObject? data, String title, String? url) {
  _window.history.pushState(data, title, url);
}
