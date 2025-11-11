class InappropriateContentException implements Exception {
  final String message;

  InappropriateContentException(this.message);

  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
