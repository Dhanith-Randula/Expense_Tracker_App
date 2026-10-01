import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getFirebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Your password is too weak. Please use a stronger password.';

      case 'operation-not-allowed':
        return 'Email and password registration is currently unavailable.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return 'Unable to create your account. Please try again.';
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully!',
          ),
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getFirebaseErrorMessage(e),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _backToLogin() {
    if (_isLoading) return;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              24,
              20,
              24,
              32,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    // Brand
                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryDark,
                            ],
                          ),
                          borderRadius:
                              BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.20),
                              blurRadius: 24,
                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons
                              .person_add_alt_1_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Start tracking your expenses with Spendly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Form card
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Account details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    colorScheme.onSurface,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'Use your email and create a secure password.',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),

                            const SizedBox(height: 20),

                            TextFormField(
                              controller:
                                  _emailController,
                              keyboardType:
                                  TextInputType
                                      .emailAddress,
                              textInputAction:
                                  TextInputAction.next,
                              enabled: !_isLoading,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Email',
                                hintText:
                                    'Enter your email',
                                prefixIcon: Icon(
                                  Icons
                                      .email_outlined,
                                ),
                              ),
                              validator: (value) {
                                final email =
                                    value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Please enter your email';
                                }

                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  return 'Please enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller:
                                  _passwordController,
                              obscureText:
                                  _obscurePassword,
                              textInputAction:
                                  TextInputAction.next,
                              enabled: !_isLoading,
                              decoration:
                                  InputDecoration(
                                labelText: 'Password',
                                hintText:
                                    'Create a password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                ),
                                suffixIcon:
                                    IconButton(
                                  tooltip:
                                      _obscurePassword
                                          ? 'Show password'
                                          : 'Hide password',
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please enter a password';
                                }

                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller:
                                  _confirmPasswordController,
                              obscureText:
                                  _obscureConfirmPassword,
                              textInputAction:
                                  TextInputAction.done,
                              enabled: !_isLoading,
                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _register();
                                }
                              },
                              decoration:
                                  InputDecoration(
                                labelText:
                                    'Confirm Password',
                                hintText:
                                    'Re-enter your password',
                                prefixIcon: const Icon(
                                  Icons
                                      .lock_reset_outlined,
                                ),
                                suffixIcon:
                                    IconButton(
                                  tooltip:
                                      _obscureConfirmPassword
                                          ? 'Show password'
                                          : 'Hide password',
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              });
                                            },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons
                                            .visibility_outlined
                                        : Icons
                                            .visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return 'Please confirm your password';
                                }

                                if (value !=
                                    _passwordController
                                        .text) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 22),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _register,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : _backToLogin,
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Spendly • Track your spending. Stay in control.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}