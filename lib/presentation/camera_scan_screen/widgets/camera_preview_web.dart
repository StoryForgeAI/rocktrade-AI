// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

void registerWebCamera() {
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory('snap-price-camera-view', (
    int viewId,
  ) {
    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    html.window.navigator.mediaDevices
        ?.getUserMedia({
          'video': {'facingMode': 'environment'},
          'audio': false,
        })
        .then((stream) {
          video.srcObject = stream;
        })
        .catchError((_) {
          html.window.navigator.mediaDevices
              ?.getUserMedia({
                'video': {'facingMode': 'user'},
                'audio': false,
              })
              .then((stream) {
                video.srcObject = stream;
              });
        });

    return video;
  });
}
