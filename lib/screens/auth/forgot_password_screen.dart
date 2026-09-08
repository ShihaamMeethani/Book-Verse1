import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();

    bool ok = false;
    try {
      ok = await auth.resetPassword(_email.text.trim());
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    setState(() {
      _loading = false;
      _sent = ok;
    });

    if (!ok && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: _sent ? _buildSuccessView(dark) : _buildFormView(dark),
        ),
      ),
    );
  }

  Widget _buildFormView(bool dark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Forgot Password?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your registered email address and we'll send you a link to reset your password.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          CustomTextField(
            controller: _email,
            label: 'Email Address',
            hint: 'name@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter your email address';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Send Reset Link',
            isLoading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 24),
          // Helpful notes box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? AppColors.surface : AppColors.paperSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Text(
                      'Important Notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• The reset link is sent directly by Firebase Auth.\n'
                  '• Check your Spam, Junk, or Promotions folder if not in your primary inbox within 2 minutes.\n'
                  '• If you signed up using Google Sign-In, no password is required — please use "Sign In with Google".',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 44,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "We've sent a password reset link to:",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email.text.trim(),
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        // Tip box about Spam
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: dark ? AppColors.surface : AppColors.paperSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.markunread_mailbox_rounded, size: 20, color: AppColors.coral),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Didn\'t receive it? Please check your Spam, Junk, or Promotions folder, as automated emails can sometimes be filtered.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          label: 'Resend Link',
          outlined: true,
          isLoading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        CustomButton(
          label: 'Back to Login',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
