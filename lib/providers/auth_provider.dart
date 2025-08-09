// d:\work\flutter\Sample_app\Flutter-School-Management-System-main\flutter\school_management\lib\providers\auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/services/auth_service.dart';

// Provides an instance of AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
