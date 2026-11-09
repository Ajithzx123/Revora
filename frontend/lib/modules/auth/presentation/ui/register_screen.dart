import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/user_model.dart';
import '../controllers/auth_controller.dart';
import 'auth_scaffold.dart';

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
  UserRole _role = UserRole.customer;
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

  // On success the router sends the user to the home for the role the backend assigned.
  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final isDealer = _role == UserRole.dealer;
    await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          role: _role,
          businessName: isDealer ? _businessController.text.trim() : null,
          city: isDealer ? _cityController.text.trim() : null,
        );
  }

  String? _required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final t = Theme.of(context).textTheme;
    final pendingEmail = auth.pendingConfirmationEmail;

    if (pendingEmail != null) {
      return AuthScaffold(
        title: 'Check your email',
        subtitle: 'One quick step before you start.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We sent a confirmation link to $pendingEmail. '
                      'Open it, then come back and sign in.',
                      style: t.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).clearError();
                context.go('/login');
              },
              child: const Text('Go to sign in'),
            ),
          ],
        ),
      );
    }

    final isDealer = _role == UserRole.dealer;
    return AuthScaffold(
      title: 'Create your account',
      subtitle: isDealer
          ? 'Apply to receive buyer requests from your city.'
          : 'Post what you want. Dealers do the chasing.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<UserRole>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: AppColors.surface,
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
              ),
              segments: const [
                ButtonSegment(
                  value: UserRole.customer,
                  label: Text('I am a buyer / seller'),
                  icon: Icon(Icons.person_outline_rounded),
                ),
                ButtonSegment(
                  value: UserRole.dealer,
                  label: Text('I am a dealer'),
                  icon: Icon(Icons.storefront_outlined),
                ),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (auth.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: t.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => _required(v, 'Enter your name'),
            ),
            if (isDealer) ...[
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _businessController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Dealership name',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) => _required(v, 'Enter your dealership name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (v) => _required(v, 'Enter your city'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your email';
                if (!v.contains('@')) return 'That email does not look right';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _onRegister(),
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Use at least 6 characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: auth.isLoading ? null : _onRegister,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(isDealer ? 'Apply as a dealer' : 'Create account'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Already have an account?', style: t.bodyMedium),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
