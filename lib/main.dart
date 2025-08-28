import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:school_management/services/auth_exception.dart';
import 'package:school_management/services/auth_service.dart';
import 'package:school_management/model_class/Alluser.dart';
import 'package:school_management/newapplicants.dart';
import 'package:school_management/studentpanel.dart';
import 'package:school_management/teacherpanel.dart';
import 'package:school_management/ui/admin_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:school_management/services/notification_service.dart';
import 'package:school_management/widgets/gradient_container.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pole star Academy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005A9C),
          primary: const Color(0xFF005A9C),
          secondary: const Color(0xFFE87722),
          background: const Color(0xFFF5F5F5),
          error: Colors.red.shade800,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF005A9C),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Color(0xFF005A9C), width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'Poppins',
            fontSize: 20.0,
          ),
          contentTextStyle: const TextStyle(
            color: Colors.black54,
            fontFamily: 'Poppins',
            fontSize: 16.0,
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const MyHomePage(title: 'Pole Star Academy');
        }
        return UserRoleRouter(user: user);
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => const Scaffold(
        body: Center(
          child: Text("Something went wrong!"),
        ),
      ),
    );
  }
}

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/school_logo.png', width: 160, height: 160),
              const SizedBox(height: 60),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserRoleRouter extends ConsumerWidget {
  final User user;
  const UserRoleRouter({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileFuture = ref.watch(userProfileProvider(user.uid));

    return userProfileFuture.when(
      data: (loggedInUser) {
        if (loggedInUser == null) {
          // This case should ideally not happen if a user is authenticated
          // but has no profile. You might want to log them out.
          return const MyHomePage(title: 'Pole Star Academy');
        }
        switch (loggedInUser.role) {
          case 'admin':
            return const AdminHomePage();
          case 'teacher':
            return Teacherpanel(currentUser: loggedInUser);
          case 'student':
            return StudentPanel(currentUser: loggedInUser);
          default:
            return const MyHomePage(title: 'Pole Star Academy');
        }
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => const Scaffold(
        body: Center(
          child: Text("Could not load user profile."),
        ),
      ),
    );
  }
}

final userProfileProvider = FutureProvider.family<Alluser?, String>((ref, uid) {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfile(uid);
});

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
            _email.text.trim(),
            _password.text.trim(),
          );
      // Navigation is now handled by the AuthWrapper
    } on AuthException catch (e) {
      _showErrorSnackBar(e.message);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordReset(BuildContext dialogContext, String email,
      GlobalKey<FormState> formKey) async {
    if (formKey.currentState?.validate() ?? false) {
      Navigator.of(dialogContext).pop();
      setState(() => _isLoading = true);
      try {
        await ref.read(authServiceProvider).sendPasswordResetEmail(email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Password reset link sent to your email.')),
          );
        }
      } on AuthException catch (e) {
        _showErrorSnackBar(e.message);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _email.text);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Enter your email address and we will send you a link to reset your password.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      (value == null || value.isEmpty || !value.contains('@'))
                          ? 'Please enter a valid email'
                          : null,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
                child: const Text('Send Link'),
                onPressed: () => _handlePasswordReset(
                    dialogContext, emailController.text.trim(), formKey)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientContainer(
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Image.asset('images/school_logo.png', height: 160),
                          ),
                          const SizedBox(height: 32),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                Text(
                                  'Welcome Back!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your account to continue',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 40),
                                TextFormField(
                                  controller: _email,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(
                                      color: Colors
                                          .black), // Ensure input text is visible
                                  validator: (value) =>
                                      (value == null || !value.contains('@'))
                                          ? 'Enter a valid email'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _password,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() =>
                                            _isPasswordVisible = !_isPasswordVisible);
                                      },
                                    ),
                                  ),
                                  style: const TextStyle(
                                      color: Colors
                                          .black), // Ensure input text is visible
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Enter your password'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        final newValue = !_rememberMe;
                                        _saveRememberMePreference(newValue);
                                        setState(() => _rememberMe = newValue!);
                                      },
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (bool? newValue) {
                                              _saveRememberMePreference(newValue!);
                                              setState(() => _rememberMe = newValue!);
                                            },
                                            checkColor: Colors.white,
                                            activeColor:
                                                Theme.of(context).colorScheme.primary,
                                          ),
                                          const Text(
                                            "Remember Me",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _showForgotPasswordDialog,
                                      child: const Text('Forgot Password?',
                                          style: TextStyle(color: Colors.white70)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _loginUser,
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRememberMePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }
}
