import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _inviteToken = TextEditingController();
  final _invitePhone = TextEditingController();
  bool _inviteMode = false;
  bool _registerMode = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _inviteToken.dispose();
    _invitePhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.sync_alt_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FlowSync Pro',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0,
                                      ),
                                ),
                                Text(
                                  'Real-time shipment orchestration',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Account')),
                          ButtonSegment(value: true, label: Text('Invite')),
                        ],
                        selected: {_inviteMode},
                        onSelectionChanged: (value) {
                          setState(() {
                            _inviteMode = value.first;
                            if (_inviteMode) {
                              _registerMode = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      if (!_inviteMode) ...[
                        if (_registerMode) ...[
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _email,
                          keyboardType: _registerMode
                              ? TextInputType.emailAddress
                              : TextInputType.text,
                          decoration: InputDecoration(
                            labelText: _registerMode
                                ? 'Work email'
                                : 'Work email or phone',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
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
                            child: Text(
                              _registerMode
                                  ? 'Already have an account? Sign In'
                                  : 'Need an account? Sign Up',
                            ),
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _inviteToken,
                          decoration: const InputDecoration(
                            labelText: 'Invite code',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _invitePhone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone (optional)',
                            prefixIcon: Icon(Icons.phone_rounded),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: auth.isLoading ? null : _submit,
                        icon: auth.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _inviteMode
                                    ? Icons.key_rounded
                                    : (_registerMode
                                        ? Icons.app_registration_rounded
                                        : Icons.login_rounded),
                              ),
                        label: Text(
                          _inviteMode
                              ? 'Access Shipment'
                              : (_registerMode ? 'Create Account' : 'Sign In'),
                        ),
                      ),
                      if (!_inviteMode && !_registerMode) ...[
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DemoButton(
                              label: 'Broker',
                              email: 'broker@flowsync.local',
                              onTap: _demo,
                            ),
                            _DemoButton(
                              label: 'Client',
                              email: 'client@flowsync.local',
                              onTap: _demo,
                            ),
                            _DemoButton(
                              label: 'Transporter',
                              email: 'transporter@flowsync.local',
                              onTap: _demo,
                            ),
                            _DemoButton(
                              label: 'Authority',
                              email: 'authority@flowsync.local',
                              onTap: _demo,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final controller = ref.read(authControllerProvider.notifier);
    if (_inviteMode) {
      await controller.inviteAccess(
        _inviteToken.text.trim(),
        phone: _invitePhone.text.trim(),
      );
    } else if (_registerMode) {
      final name = _name.text.trim();
      final phone = _phone.text.trim();
      final email = _email.text.trim();
      if (name.isEmpty ||
          phone.isEmpty ||
          email.isEmpty ||
          _password.text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name, phone, email and password are required.'),
          ),
        );
        return;
      }
      await controller.register(
        name: name,
        phone: phone,
        email: email,
        password: _password.text,
      );
    } else {
      await controller.login(_email.text.trim(), _password.text);
    }
  }

  Future<void> _demo(String email) async {
    setState(() {
      _inviteMode = false;
      _registerMode = false;
      _email.text = email;
      _password.text = 'Password123!';
    });
    await _submit();
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({
    required this.label,
    required this.email,
    required this.onTap,
  });

  final String label;
  final String email;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: () => onTap(email), child: Text(label));
  }
}
