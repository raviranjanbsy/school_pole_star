import 'package:flutter/material.dart';
import 'package:school_management/main.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/widgets/gradient_container.dart';

class EditUserPage extends StatefulWidget {
  final Alluser userToEdit;

  const EditUserPage({super.key, required this.userToEdit});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userToEdit.name);
    _usernameController =
        TextEditingController(text: widget.userToEdit.username);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final updatedUser = Alluser(
      uid: widget.userToEdit.uid,
      email: widget.userToEdit.email, // Email is not editable
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      role: widget.userToEdit.role, // Role is changed separately
      status: widget.userToEdit.status,
      image: widget.userToEdit.image, // Image editing not included here
    );

    try {
      await _authService.updateUserProfile(updatedUser);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User details updated successfully!')),
        );
        Navigator.pop(context, true); // Return true to signal success
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Edit User'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.userToEdit.email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email (cannot be changed)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.black12,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
