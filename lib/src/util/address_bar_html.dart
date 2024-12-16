import 'dart:html' as html;

String get $hrefPylon => html.window.location.href;

void $pushHrefPylon(data, String title, String? url) =>
    html.window.history.pushState(data, title, url);
