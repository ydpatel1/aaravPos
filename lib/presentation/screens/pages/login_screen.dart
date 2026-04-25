import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'kiosk@oshawa.com');
  final _passwordController = TextEditingController(text: 'Admin@123');

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    context.read<AuthBloc>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE72646), Color(0xFFF0384C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state.email.isNotEmpty && _emailController.text != state.email) {
                      _emailController.text = state.email;
                    }
                    if (state.status == AuthStatus.authenticated) {
                      context.go(AppRoutes.home);
                    }
                  },
                  builder: (context, state) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'AaravPOS',
                              style: TextStyle(
                                fontSize: 44,
                                color: Color(0xFFE12242),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text('Email Address'),
                          const SizedBox(height: 8),
                          AppTextField(
                            label: 'Email',
                            controller: _emailController,
                            validator: Validators.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 18),
                          const Text('Password'),
                          const SizedBox(height: 8),
                          AppTextField(
                            label: 'Password',
                            controller: _passwordController,
                            validator: Validators.password,
                            obscureText: true,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: state.rememberMe,
                                onChanged: (value) => context
                                    .read<AuthBloc>()
                                    .setRememberMe(value ?? false),
                              ),
                              const Text('Remember Me'),
                              const Spacer(),
                              const Text(
                                'Forgot password?',
                                style: TextStyle(color: Color(0xFFE12242)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Sign In',
                            isLoading: state.status == AuthStatus.loading,
                            onPressed: _onLogin,
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'v0.0.1',
                              style: TextStyle(color: Color(0xFF9A9A9A)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
