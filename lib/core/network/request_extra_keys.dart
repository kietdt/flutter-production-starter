/// Keys stored in [RequestOptions.extra] to pass per-request flags from
/// [NetworkClient] to the interceptors. Centralized to avoid typos.
class RequestExtraKeys {
  RequestExtraKeys._();

  /// `false` for endpoints that must not carry a token nor trigger a refresh
  /// (login, refresh, logout).
  static const String requiresAuth = 'requiresAuth';

  /// Set on a request replayed after a refresh, so a second 401 is not retried.
  static const String isRetry = 'isRetry';
}
