import 'dart:html' as html;

html.EventListener? _visibilityHandler;
html.EventListener? _beforeUnloadHandler;

/// Đăng ký các sự kiện trình duyệt để theo dõi hiện diện khách hàng trên bàn
void registerWebPresence(
  String tableId,
  Future<void> Function() onLeave,
  Future<void> Function() onRejoin,
) {
  unregisterWebPresence();

  _visibilityHandler = (_) async {
    if (html.document.visibilityState == 'hidden') {
      // Tab bị ẩn (gạt ra nền, đóng tab, chuyển tab) → rời bàn
      await onLeave();
    } else if (html.document.visibilityState == 'visible') {
      // Tab được mở lại → vào bàn lại
      await onRejoin();
    }
  };

  _beforeUnloadHandler = (_) {
    // Đóng tab/trình duyệt hoàn toàn → rời bàn (fire-and-forget)
    onLeave();
  };

  html.document.addEventListener('visibilitychange', _visibilityHandler!);
  html.window.addEventListener('beforeunload', _beforeUnloadHandler!);
}

/// Hủy đăng ký tất cả các sự kiện trình duyệt
void unregisterWebPresence() {
  if (_visibilityHandler != null) {
    html.document.removeEventListener('visibilitychange', _visibilityHandler!);
    _visibilityHandler = null;
  }
  if (_beforeUnloadHandler != null) {
    html.window.removeEventListener('beforeunload', _beforeUnloadHandler!);
    _beforeUnloadHandler = null;
  }
}
