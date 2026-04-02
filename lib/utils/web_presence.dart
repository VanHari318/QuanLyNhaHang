/// Conditional export: uses dart:html on web, stub on mobile/desktop
export 'web_presence_stub.dart'
    if (dart.library.html) 'web_presence_web.dart';
