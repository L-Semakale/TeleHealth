import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/common_widgets.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Telemedicine Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Phone number required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                  ),
                  const SizedBox(height: 16),
                  if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 4),
                  FilledButton(
                    onPressed: auth.loading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final ok = await ref.read(authControllerProvider.notifier).login(
                                  _phoneController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                            if (!mounted || !ok) return;
                            context.go('/home');
                          },
                    child: auth.loading ? const CircularProgressIndicator() : const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Register as Patient'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Full name required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Phone number required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v == null || v.length < 6) ? 'At least 6 chars' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm password'),
                    validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 16),
                  if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
                  FilledButton(
                    onPressed: auth.loading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            final id = await ref.read(authControllerProvider.notifier).register(
                                  _fullName.text.trim(),
                                  _phone.text.trim(),
                                  _password.text.trim(),
                                );
                            if (!mounted || id == null) return;
                            await showDialog<void>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Registration successful'),
                                content: Text('Your anonymous ID is $id.\nPlease save it safely.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Continue to login'),
                                  ),
                                ],
                              ),
                            );
                            if (mounted) context.go('/login');
                          },
                    child: auth.loading ? const CircularProgressIndicator() : const Text('Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordPlaceholderScreen extends StatelessWidget {
  const ForgotPasswordPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const EmptyView(
        message: 'Password reset flow will be available soon. Please contact support.',
      ),
    );
  }
}
