/// An access/refresh token pair, as returned by the refresh endpoint.
class TokenPair {
  final String accessToken;
  final String refreshToken;

  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
  });
}
