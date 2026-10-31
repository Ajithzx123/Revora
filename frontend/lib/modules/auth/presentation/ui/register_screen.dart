import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/user_model.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessController = TextEditingController();
  final _cityController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _businessController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: email,
          password: password,
          fullName: name,
          role: _selectedRole,
          businessName: _selectedRole == UserRole.dealer
              ? _businessController.text.trim()
              : null,
          city: _selectedRole == UserRole.dealer
              ? _cityController.text.trim()
              : null,
        );

    if (success && mounted) {
      // The role comes from the backend, not from what was picked on this form.
      final user = ref.read(authControllerProvider).user;
      if (user != null) _navigateByRole(user.role);
    }
  }

  void _navigateByRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        context.go('/customer/home');
        break;
      case UserRole.dealer:
        context.go('/dealer/home');
        break;
      case UserRole.admin:
        context.go('/admin/dashboard');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    final pendingEmail = authState.pendingConfirmationEmail;
    if (pendingEmail != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        size: 64, color: AppColors.accent),
                    const SizedBox(height: 20),
                    Text('Check your email',
                        style: isDark
                            ? AppTextStyles.headlineMediumDark
                            : AppTextStyles.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'We sent a confirmation link to $pendingEmail. '
                      'Open it, then come back and sign in.',
                      style: isDark
                          ? AppTextStyles.bodyMediumDark
                          : AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).clearError();
                        context.go('/login');
                      },
                      child: const Text('Go to sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 440 : 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join the Revora Network',
                      style: (isDark
                              ? AppTextStyles.headlineMediumDark
                              : AppTextStyles.headlineMedium)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Buy, sell, and deal verified vehicles seamlessly',
                      style: isDark
                          ? AppTextStyles.bodyMediumDark
                          : AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    // Role selector segment
                    Text(
                      'I want to register as a:',
                      style: isDark
                          ? AppTextStyles.labelMediumDark
                          : AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: const [
                        ButtonSegment(
                          value: UserRole.customer,
                          label: Text('Customer'),
                          icon: Icon(Icons.person_outline),
                        ),
                        ButtonSegment(
                          value: UserRole.dealer,
                          label: Text('Dealer'),
                          icon: Icon(Icons.storefront_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Full Name Field
                    Text(
                      'Full Name',
                      style: isDark
                          ? AppTextStyles.labelMediumDark
                          : AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'John Doe',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    if (_selectedRole == UserRole.dealer) ...[
                      Text(
                        'Business Name',
                        style: isDark
                            ? AppTextStyles.labelMediumDark
                            : AppTextStyles.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _businessController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Apex Motors',
                          prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter your business name'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'City',
                        style: isDark
                            ? AppTextStyles.labelMediumDark
                            : AppTextStyles.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _cityController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Bengaluru',
                          prefixIcon: Icon(Icons.location_city_outlined, size: 20),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter your city'
                            : null,
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Email Field
                    Text(
                      'Email Address',
                      style: isDark
                          ? AppTextStyles.labelMediumDark
                          : AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'name@company.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    Text(
                      'Password',
                      style: isDark
                          ? AppTextStyles.labelMediumDark
                          : AppTextStyles.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onRegister(),
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        prefixIcon:
                            const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Error Message Display
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Text(
                          authState.errorMessage!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sign Up Action Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _onRegister,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Navigation to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: isDark
                              ? AppTextStyles.bodySmallDark
                              : AppTextStyles.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
