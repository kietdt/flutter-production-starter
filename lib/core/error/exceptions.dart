/// Core Error Module
/// Responsibility: Define data-level exceptions.
/// 
/// These are thrown by datasources and caught by repositories to be converted into Failures.

class ServerException implements Exception {
  final String message;
  ServerException({this.message = 'Server Exception'});
}
