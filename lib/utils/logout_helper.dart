import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_management/main.dart';
import 'package:school_management/services/auth_service.dart';

/// Shows a confirmation dialog and handles the logout process.
///
/// This function displays an `AlertDialog` to confirm the user's intent to log out.
/// If confirmed, it signs the user out using [AuthService] and navigates
/// to the home page, clearing the navigation stack.
Future<void> showLogoutConfirmationDialog(
    BuildContext context, WidgetRef ref) async {
  // It's better to get the service instance once.
  final authService = AuthService();
  final uid = authService.getAuth().currentUser?.uid;

  final bool? confirmLogout = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      );
    },
  );

  // Check if the widget is still in the tree and if logout was confirmed.
  if (confirmLogout == true && context.mounted) {
    try {
      await authService.signOut();
      if (context.mounted) {
        // The AuthWrapper will automatically navigate to the login screen.
        // No need to manually push a new route.
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }
}