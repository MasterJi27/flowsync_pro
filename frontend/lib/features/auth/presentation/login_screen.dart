import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/animated_background.dart';
import '../../../shared/widgets/glass_card.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _inviteToken = TextEditingController();
  final _invitePhone = TextEditingController();

  bool _inviteMode = false;
  bool _registerMode = false;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _backendOnline = true;

  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    Future<void>.microtask(_checkBackendStatus);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _inviteToken.dispose();
    _invitePhone.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        if (_looksLikeBackendError(error) && _backendOnline) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _backendOnline = false);
            }
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      if (next.isAuthenticated && !_backendOnline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _backendOnline = true);
          }
        });
      }
    });

    return Scaffold(
      body: AnimatedMeshBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    _buildHeroHeader(scheme),
                    const SizedBox(height: 32),
                    GlassCard(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildModeSwitcher(scheme),
                          const SizedBox(height: 16),
                          _buildBackendStatusBanner(scheme),
                          const SizedBox(height: 8),
                          if (!_inviteMode) ...[
                            if (_registerMode) ...[
                              _buildTextField(
                                controller: _name,
                                label: 'Full name',
                                icon: Icons.badge_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                controller: _phone,
                                label: 'Phone number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _buildTextField(
                              controller: _email,
                              label: _registerMode
                                  ? 'Work email address'
                                  : 'Work email or phone',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _buildPasswordField(),
                            if (_registerMode) ...[
                              const SizedBox(height: 14),
                              _buildTermsCheckbox(scheme),
                            ],
                            const SizedBox(height: 8),
                            _buildToggleMode(scheme),
                            if (!_registerMode) ...[
                              const SizedBox(height: 2),
                              _buildForgotPassword(scheme, auth.isLoading),
                            ],
                          ] else ...[
                            _buildTextField(
                              controller: _inviteToken,
                              label: 'Invite code',
                              icon: Icons.key_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _invitePhone,
                              label: 'Phone for verification (optional)',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                          const SizedBox(height: 24),
                          DepthButton(
                            label: _inviteMode
                                ? 'Open Shipment'
                                : (_registerMode
                                    ? 'Create Account'
                                    : 'Sign In'),
                            icon: _inviteMode
                                ? Icons.key_rounded
                                : (_registerMode
                                    ? Icons.person_add_rounded
                                    : Icons.login_rounded),
                            onPressed: _canSubmit ? _submit : null,
                            isLoading: auth.isLoading,
                            color: scheme.primary,
                          ),
                          if (!_inviteMode && !_registerMode) ...[
                            const SizedBox(height: 14),
                            _buildProviderSignIns(scheme, auth.isLoading),
                          ],
                          if (!_inviteMode &&
                              !_registerMode &&
                              AppConfig.enableDemoAuth) ...[
                            const SizedBox(height: 28),
                            _buildDivider(scheme),
                            const SizedBox(height: 20),
                            _buildQuickAccess(scheme),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFooter(scheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ColorScheme scheme) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatController.value * 8 - 4),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: scheme.secondary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.sync_alt_rounded,
                  size: 40,
                  color: scheme.onPrimary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'FlowSync Pro',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                fontSize: 32,
                color: scheme.onSurface,
              ),
        )
            .animate()
            .fadeIn(duration: 600.milliseconds, delay: 100.milliseconds)
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 500.milliseconds,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: 6),
        Text(
          'Real-time shipment orchestration',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
        )
            .animate()
            .fadeIn(duration: 600.milliseconds, delay: 250.milliseconds)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: 400.milliseconds,
              curve: Curves.easeOut,
            ),
        const SizedBox(height: 6),
        Text(
          'Plan routes, monitor ETAs, and resolve exceptions faster.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
        )
            .animate()
            .fadeIn(duration: 550.milliseconds, delay: 320.milliseconds)
            .slideY(begin: 0.15, end: 0, duration: 380.milliseconds),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Built for brokers, carriers, and clients',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.milliseconds, delay: 400.milliseconds)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildModeSwitcher(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Account',
              icon: Icons.person_outline_rounded,
              isActive: !_inviteMode,
              onTap: () => setState(() {
                _inviteMode = false;
              }),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Invite',
              icon: Icons.key_rounded,
              isActive: _inviteMode,
              onTap: () => setState(() {
                _inviteMode = true;
                _registerMode = false;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackendStatusBanner(ColorScheme scheme) {
    if (_backendOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Service unavailable. Check your connection and tap Retry.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: _checkBackendStatus,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _looksLikeBackendError(String message) {
    final text = message.toLowerCase();
    return text.contains('server unavailable') ||
        text.contains('cannot connect to server') ||
        text.contains('connection refused') ||
        text.contains('socketexception');
  }

  Future<void> _checkBackendStatus() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get<Map<String, dynamic>>('/health');
      final status = response.data?['status'];
      final isOnline = response.statusCode == 200 && status == 'ok';
      if (mounted) {
        setState(() => _backendOnline = isOnline);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _backendOnline = false);
      }
    }
  }

  Future<bool> _ensureBackendOnline() async {
    if (_backendOnline) {
      return true;
    }
    await _checkBackendStatus();
    if (_backendOnline) {
      return true;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service is unavailable. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    ).animate().fadeIn(duration: 400.milliseconds).slideY(
          begin: 0.15,
          end: 0,
          duration: 300.milliseconds,
          curve: Curves.easeOut,
        );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _password,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    ).animate().fadeIn(duration: 400.milliseconds).slideY(
          begin: 0.15,
          end: 0,
          duration: 300.milliseconds,
          curve: Curves.easeOut,
        );
  }

  Widget _buildTermsCheckbox(ColorScheme scheme) {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleMode(ColorScheme scheme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          setState(() {
            _registerMode = !_registerMode;
            if (_registerMode) {
              _email.clear();
              _password.clear();
            } else {
              _name.clear();
              _phone.clear();
              _email.clear();
              _password.clear();
            }
          });
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          _registerMode
              ? 'Already have an account? Sign In'
              : 'Need an account? Sign Up',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword(ColorScheme scheme, bool isLoading) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: isLoading ? null : () => context.push('/forgot-password'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot password? Reset it',
          style: TextStyle(
            color: scheme.secondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'DEMO ROLES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ],
    );
  }

  Widget _buildProviderSignIns(ColorScheme scheme, bool isLoading) {
    final googleStyle = OutlinedButton.styleFrom(
      foregroundColor: scheme.onSurface,
      backgroundColor: scheme.surface,
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    final phoneStyle = OutlinedButton.styleFrom(
      foregroundColor: scheme.onSurface,
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (!await _ensureBackendOnline()) {
                    return;
                  }
                  HapticFeedback.lightImpact();
                  await ref
                      .read(authControllerProvider.notifier)
                      .loginWithGoogle();
                },
          style: googleStyle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _googleMark(scheme),
              const SizedBox(width: 10),
              const Text('Continue with Google'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  if (!await _ensureBackendOnline()) {
                    return;
                  }
                  _openPhoneOtpSheet(scheme);
                },
          icon: const Icon(Icons.phone_android_rounded, size: 18),
          label: const Text('Continue with SMS OTP'),
          style: phoneStyle,
        ),
      ],
    );
  }

  Widget _googleMark(ColorScheme scheme) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: ShaderMask(
        shaderCallback: (rect) {
          return const LinearGradient(
            colors: [
              Color(0xFF4285F4),
              Color(0xFF34A853),
              Color(0xFFFBBC05),
              Color(0xFFEA4335),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ).createShader(rect);
        },
        child: const Text(
          'G',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _openPhoneOtpSheet(ColorScheme scheme) async {
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    String? verificationId;
    bool sendingCode = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            Future<void> sendOtp() async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter your phone number first.'),
                  ),
                );
                return;
              }

              setModalState(() => sendingCode = true);
              try {
                final id = await ref
                    .read(authControllerProvider.notifier)
                    .sendPhoneOtp(phone);
                setModalState(() {
                  verificationId = id;
                  sendingCode = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('OTP sent successfully.')),
                  );
                }
              } catch (error) {
                setModalState(() => sendingCode = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            }

            Future<void> verifyOtp() async {
              final phone = phoneController.text.trim();
              final code = codeController.text.trim();
              final id = verificationId;
              if (phone.isEmpty || code.isEmpty || id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter phone, request OTP, then enter code.'),
                  ),
                );
                return;
              }

              await ref
                  .read(authControllerProvider.notifier)
                  .verifyPhoneOtpAndLogin(
                    phoneNumber: phone,
                    verificationId: id,
                    smsCode: code,
                  );

              if (!mounted) {
                return;
              }

              final auth = ref.read(authControllerProvider);
              if (auth.isAuthenticated) {
                Navigator.of(context).pop();
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 18,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SMS OTP Sign-in',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: phoneController,
                      label: 'Phone number (+country code)',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: codeController,
                      label: 'SMS code',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: sendingCode ? null : sendOtp,
                            child: Text(
                              sendingCode ? 'Sending...' : 'Send OTP',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: verifyOtp,
                            child: const Text('Verify and sign in'),
                          ),
                        ),
                      ],
                    ),
                    if (verificationId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Code sent. Enter it to continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    phoneController.dispose();
    codeController.dispose();
  }

  Widget _buildQuickAccess(ColorScheme scheme) {
    final roles = [
      _QuickRole(
        label: 'Broker',
        email: 'broker@flowsync.local',
        color: scheme.primary,
        icon: Icons.business_center_rounded,
      ),
      _QuickRole(
        label: 'Client',
        email: 'client@flowsync.local',
        color: scheme.secondary,
        icon: Icons.person_rounded,
      ),
      _QuickRole(
        label: 'Transporter',
        email: 'transporter@flowsync.local',
        color: scheme.tertiary,
        icon: Icons.local_shipping_rounded,
      ),
      _QuickRole(
        label: 'Authority',
        email: 'authority@flowsync.local',
        color: scheme.error,
        icon: Icons.verified_user_rounded,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: roles
          .map((r) => _QuickRoleChip(role: r, onTap: () => _demo(r.email)))
          .toList(),
    )
        .animate()
        .fadeIn(duration: 500.milliseconds, delay: 200.milliseconds)
        .slideY(begin: 0.2, end: 0, duration: 400.milliseconds);
  }

  Widget _buildFooter(ColorScheme scheme) {
    return Column(
      children: [
        Text(
          'Faster decisions. Fewer delays.',
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield_rounded,
              size: 12,
              color: scheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Secure collaboration for every shipment',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool get _canSubmit {
    if (_inviteMode) return _inviteToken.text.trim().isNotEmpty;
    if (_registerMode) {
      return _name.text.trim().isNotEmpty &&
          _phone.text.trim().isNotEmpty &&
          _email.text.trim().isNotEmpty &&
          _password.text.isNotEmpty &&
          _agreedToTerms;
    }
    return _email.text.trim().isNotEmpty && _password.text.isNotEmpty;
  }

  Future<void> _submit() async {
    if (!await _ensureBackendOnline()) {
      return;
    }
    HapticFeedback.lightImpact();
    final controller = ref.read(authControllerProvider.notifier);
    if (_inviteMode) {
      await controller.inviteAccess(
        _inviteToken.text.trim(),
        phone: _invitePhone.text.trim(),
      );
    } else if (_registerMode) {
      await controller.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
    } else {
      await controller.login(_email.text.trim(), _password.text);
    }
  }

  Future<void> _demo(String email) async {
    if (!AppConfig.enableDemoAuth) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _inviteMode = false;
      _registerMode = false;
      _email.text = email;
      _password.text = 'Password123!';
    });
    await _submit();
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.milliseconds,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickRole {
  final String label;
  final String email;
  final Color color;
  final IconData icon;

  _QuickRole({
    required this.label,
    required this.email,
    required this.color,
    required this.icon,
  });
}

class _QuickRoleChip extends StatefulWidget {
  const _QuickRoleChip({required this.role, required this.onTap});

  final _QuickRole role;
  final VoidCallback onTap;

  @override
  State<_QuickRoleChip> createState() => _QuickRoleChipState();
}

class _QuickRoleChipState extends State<_QuickRoleChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: 120.milliseconds,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: widget.role.color.withValues(alpha: _pressed ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.role.color.withValues(alpha: _pressed ? 0.4 : 0.2),
            width: 1.5,
          ),
        ),
        transform: Matrix4.identity()..scale(_pressed ? 0.95 : 1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.role.icon, size: 16, color: widget.role.color),
            const SizedBox(width: 6),
            Text(
              widget.role.label,
              style: TextStyle(
                color: widget.role.color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
