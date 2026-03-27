/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (HTTP $statusCode)' : ''}';
}

/// Custom exception for network errors
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}