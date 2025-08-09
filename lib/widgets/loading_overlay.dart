import 'package:flutter/material.dart';

/// A reusable widget that displays a full-screen loading overlay
/// on top of its child content when `isLoading` is true.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message; // Optional message to display below the indicator

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child, // The main content of the screen
        if (isLoading)
          // AbsorbPointer prevents user interaction with the content below
          AbsorbPointer(
            absorbing: true,
            child: Container(
              color:
                  Colors.black.withOpacity(0.5), // Semi-transparent background
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null && message!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        message!,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
