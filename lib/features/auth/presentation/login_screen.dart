import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../../core/constants/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'auth_providers.dart';

/// Phase de l'envoi du magic link.
enum _LinkPhase { idle, sending, sent, error }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _LinkPhase _phase = _LinkPhase.idle;
  String? _lastEmail;
  String? _errorMessage;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailCtl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailCtl.text.trim();
    setState(() {
      _phase = _LinkPhase.sending;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendMagicLink(email);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _phase = _LinkPhase.sent;
        _lastEmail = email;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _LinkPhase.error;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _LinkPhase.error;
        _errorMessage = Strings.authError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Halos cohérents avec le HomeShell
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -1.0),
                  radius: 1.4,
                  colors: [Color(0x1A8A2BE2), Colors.transparent],
                  stops: [0, 1],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(1.0, -0.8),
                  radius: 1.0,
                  colors: [Color(0x10D4AF37), Colors.transparent],
                  stops: [0, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    _BrandBlock(),
                    const SizedBox(height: 48),
                    if (_phase == _LinkPhase.sent)
                      _SentBlock(
                        email: _lastEmail ?? '',
                        onResend: () {
                          setState(() => _phase = _LinkPhase.idle);
                        },
                      )
                    else
                      _FormBlock(
                        controller: _emailCtl,
                        sending: _phase == _LinkPhase.sending,
                        errorMessage: _phase == _LinkPhase.error
                            ? (_errorMessage ?? Strings.authError)
                            : null,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty || !_emailRegex.hasMatch(value)) {
                            return Strings.authEmailInvalid;
                          }
                          return null;
                        },
                        onSubmit: _send,
                      ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.authTitle,
          style: AppTypography.num(
            size: 44,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: -0.03,
            height: 1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          Strings.authTagline,
          style: AppTypography.inter(
            size: 15,
            weight: FontWeight.w500,
            color: AppColors.text1,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FormBlock extends StatelessWidget {
  const _FormBlock({
    required this.controller,
    required this.sending,
    required this.errorMessage,
    required this.validator,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool sending;
  final String? errorMessage;
  final FormFieldValidator<String> validator;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          Strings.authEmailLabel.toUpperCase(),
          style: AppTypography.eyebrow(size: 11),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !sending,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.send,
          onFieldSubmitted: (_) => onSubmit(),
          validator: validator,
          style: AppTypography.inter(size: 15, color: AppColors.text0),
          decoration: InputDecoration(
            hintText: Strings.authEmailPlaceholder,
            hintStyle: AppTypography.inter(size: 15, color: AppColors.text2),
            filled: true,
            fillColor: const Color(0x0AFFFFFF),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gold),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.down),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.down),
            ),
            errorStyle: AppTypography.inter(size: 12, color: AppColors.down),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            style: AppTypography.inter(size: 12.5, color: AppColors.down),
          ),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.gold, AppColors.goldDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withAlpha(0x59),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: sending ? null : onSubmit,
                child: Center(
                  child: sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Color(0xFF191100)),
                          ),
                        )
                      : Text(
                          Strings.authSendMagicLink,
                          style: AppTypography.inter(
                            size: 15,
                            weight: FontWeight.w700,
                            color: const Color(0xFF191100),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          Strings.authMagicLinkHint,
          textAlign: TextAlign.center,
          style: AppTypography.inter(
            size: 12,
            color: AppColors.text2,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SentBlock extends StatelessWidget {
  const _SentBlock({required this.email, required this.onResend});

  final String email;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.goldSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withAlpha(0x59)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  size: 22, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Strings.authMagicLinkSent(email),
                  style: AppTypography.inter(
                    size: 14,
                    color: AppColors.text0,
                    height: 1.4,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onResend,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            Strings.authMagicLinkResend,
            style: AppTypography.inter(
              size: 14,
              weight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }
}
