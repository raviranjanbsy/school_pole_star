import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/model_class/school_class.dart';
import 'package:school_management/providers/auth_provider.dart';
import 'package:school_management/services/auth_service.dart';

final communicationProvider =
    StateNotifierProvider<_CommunicationNotifier, CommunicationState>(
  (ref) => _CommunicationNotifier(ref.read(authServiceProvider)),
);

class CommunicationState {
  final List<SchoolClass> classes;
  final List<Alluser> users;
  CommunicationState(this.classes, this.users);
}

class _CommunicationNotifier extends StateNotifier<CommunicationState> {
  final AuthService _authService;

  _CommunicationNotifier(this._authService) : super(CommunicationState([], []));

  Future<void> loadData() async {
    final classes = await _authService.fetchAllSchoolClasses();
    final users = await _authService.fetchAllUsers();
    state = CommunicationState(classes, users);
  }
}
