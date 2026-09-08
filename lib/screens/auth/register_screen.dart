import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../main_nav/main_navigation_screen.dart';
import '../admin/admin_navigation_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    try {
      final ok = await auth.register(_name.text.trim(), _email.text.trim(), _password.text);
      if (!mounted) return;
      if (ok) {
        final destination = auth.isAdmin
            ? const AdminNavigationScreen()
            : const MainNavigationScreen();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      } else if (auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(auth.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Registration failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 350),
                  child: Text(
                    'Create Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeInUp(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Join thousands of readers and start exploring BookVerse today.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                CustomTextField(
                  controller: _name,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _email,
                  label: 'Email address',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _password,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscure,
                  validator: (v) => (v != _password.text) ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  label: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or sign up with',
                        style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Continue with Google',
                  outlined: true,
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final authProv = context.read<AuthProvider>();
                    final ok = await authProv.loginWithGoogle();
                    if (!mounted) return;
                    if (ok) {
                      final destination = authProv.isAdmin
                          ? const AdminNavigationScreen()
                          : const MainNavigationScreen();
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => destination),
                        (route) => false,
                      );
                    } else if (authProv.errorMessage != null) {
                      messenger.showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(authProv.errorMessage!),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 28),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

