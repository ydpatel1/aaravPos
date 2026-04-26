import 'package:aaravpos/core/utils/extensions/space_extension.dart';
import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_styles.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../shared/widgets/aarav_pos_logo.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state.email.isNotEmpty &&
                            _emailController.text != state.email) {
                          _emailController.text = state.email;
                        }
                        if (state.password.isNotEmpty &&
                            _passwordController.text != state.password) {
                          _passwordController.text = state.password;
                        }
                        if (state.status == AuthStatus.authenticated) {
                          context.go(AppRoutes.home);
                        }
                        if (state.status == AuthStatus.failure) {
                          context.showSnackBar(
                            state.errorMessage ??
                                'Unable to login. Please try again.',
                            isError: true,
                          );
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
                                child: AaravPosLogo(size: LogoSize.large),
                              ),
                              15.vs,
                              const Text(
                                'Email Address',
                                style: AppStyles.fieldLabel,
                              ),
                              8.vs,
                              AppTextField(
                                hint: "Enter email",
                                controller: _emailController,
                                validator: Validators.email,
                                prefix: Icon(Icons.email),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              18.vs,
                              const Text(
                                'Password',
                                style: AppStyles.fieldLabel,
                              ),
                              8.vs,
                              BlocBuilder<AuthBloc, AuthState>(
                                buildWhen: (prev, curr) =>
                                    prev.isPasswordVisible !=
                                    curr.isPasswordVisible,
                                builder: (context, state) {
                                  return AppTextField(
                                    controller: _passwordController,
                                    hint: "Enter password",
                                    validator: Validators.password,
                                    prefix: const Icon(Icons.lock),
                                    obscureText: !state.isPasswordVisible,
                                    suffix: IconButton(
                                      icon: Icon(
                                        state.isPasswordVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: context
                                          .read<AuthBloc>()
                                          .togglePasswordVisibility,
                                    ),
                                  );
                                },
                              ),
                              15.vs,
                              Row(
                                children: [
                                  Transform.translate(
                                    offset: Offset(-5, 0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 25,
                                          width: 30,
                                          child: Checkbox(
                                            value: state.rememberMe,
                                            onChanged: (value) => context
                                                .read<AuthBloc>()
                                                .setRememberMe(value ?? false),
                                          ),
                                        ),
                                        const Text(
                                          'Remember Me',
                                          style: AppStyles.fieldLabel,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Spacer(),
                                  const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Color(0xFFE12242)),
                                  ),
                                ],
                              ),
                              15.vs,
                              AppButton(
                                label: 'Sign In',
                                isLoading: state.status == AuthStatus.loading,
                                onPressed: _onLogin,
                              ),
                              12.vs,
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
        ),
      ),
    );
  }
}
