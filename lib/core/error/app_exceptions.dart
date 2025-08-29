sealed class AppException implements Exception {
  const AppException(this.message);
  
  final String message;
  
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message, this.errors);
  
  final Map<String, List<String>> errors;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message, [this.statusCode]);
  
  final int? statusCode;
}

class CacheException extends AppException {
  const CacheException(super.message);
}

class UnknownException extends AppException {
  const UnknownException(super.message);
}
