/// A custom exception class for handling authentication-related errors
/// in a structured way throughout the app.
class AuthException implements Exception {
  /// A user-friendly message describing the error.
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
