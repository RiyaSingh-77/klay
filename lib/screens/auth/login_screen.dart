import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

// LoginScreen is intentionally a MOCK. JSONPlaceholder has no /login or
// /auth endpoint — there is no real account system behind this app. Any
// non-empty email/password "signs in." This exists purely to match the
// product flow from the design inspo, not to demonstrate real
// authentication. Worth saying exactly this if asked, rather than
// implying there's a real backend behind it.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter an email and password')));
      return;
    }
    // No real auth call — straight to the feed.
    Navigator.pushReplacementNamed(context, AppRoutes.feed);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('WELCOME BACK', style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text('good to see you again.', style: textTheme.headlineLarge?.copyWith(fontSize: 30)),
              const SizedBox(height: 32),
              Text('EMAIL', style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@example.com'),
              ),
              const SizedBox(height: 20),
              Text('PASSWORD', style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
              const SizedBox(height: 28),
              ElevatedButton(onPressed: _signIn, child: const Text('SIGN IN')),
            ],
          ),
        ),
      ),
    );
  }
}