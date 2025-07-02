import 'dart:async';
import 'package:app_links/app_links.dart';

typedef FeedIdCallback = void Function(String feedId);

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _sub;

  FeedIdCallback? onFeedIdReceived;

  bool _hasProcessed = false;

  void init() {
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _processUri(uri);
    }, onError: (err) {
      print('딥링크 수신 오류: $err');
    });
  }

  Future<Uri?> getInitialUri() async {
    try {
      final uri = await _appLinks.getInitialLink();
      _processUri(uri);
      return uri;
    } catch (e) {
      print('getInitialLink() error: $e');
      return null;
    }
  }

  void _processUri(Uri? uri) {
    if (uri == null) return;
    if (_hasProcessed) return;

    if (uri.scheme == 'wearly' &&
        uri.host == 'deeplink' &&
        uri.path == '/feedid' &&
        uri.queryParameters.containsKey('id')) {
      final feedId = uri.queryParameters['id']!;
      onFeedIdReceived?.call(feedId);
      _hasProcessed = true;
    }
  }

  /// 딥링크 처리 완료 후 플래그 초기화용 메서드
  void resetProcessedFlag() {
    _hasProcessed = false;
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
