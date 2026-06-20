import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

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

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // One-off serif display font just for the hero line — the rest of the
    // app stays on Poppins/Inter/Roboto from AppTheme. Mixing in a serif
    // here is what gives this specific headline the "editorial" feel from
    // the mockup; it's a deliberate accent, not a base theme change.
    final heroSerif = GoogleFonts.fraunces(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color: AppTheme.textDark,
      height: 1.15,
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Back button + version badge row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _goBack,
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back, size: 18, color: AppTheme.textDark),
                        const SizedBox(width: 6),
                        Text(
                          'BACK',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'V 0.1 · ALPHA',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'WELCOME BACK',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),

              // Headline with the italic accent word, matching the mockup's
              // "good to *see* you again."
              RichText(
                text: TextSpan(
                  style: heroSerif,
                  children: [
                    const TextSpan(text: 'good to '),
                    TextSpan(
                      text: 'see',
                      style: heroSerif.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const TextSpan(text: ' you again.'),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Sign in to your studio. Your drafts, albums and quiet '
                'corners are waiting.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textDark.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'EMAIL',
                style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'mira@gmail.com',
                  prefixIcon: Icon(Icons.mail_outline, color: AppTheme.primary),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'PASSWORD',
                style: textTheme.bodyMedium?.copyWith(letterSpacing: 1, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary),
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signIn,
                  child: const Text('SIGN IN'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}