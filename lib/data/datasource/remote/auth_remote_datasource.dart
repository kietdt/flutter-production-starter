/// Data Remote Datasource Module
/// Responsibility: Communicate with external APIs/services.

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String email, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Perform API call
    return {'id': '1', 'email': email};
  }
}
