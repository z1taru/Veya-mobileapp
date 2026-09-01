final class DeepLinkCoordinator {
  Uri? _pendingUri;

  Uri? get pendingUri => _pendingUri;

  void defer(Uri uri) {
    if (uri.scheme == 'veya') _pendingUri = uri;
  }

  Uri? takePending() {
    final uri = _pendingUri;
    _pendingUri = null;
    return uri;
  }
}
