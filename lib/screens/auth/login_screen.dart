import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:doss_core/doss_core.dart';
import '../../blocs/auth/driver_auth_bloc.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});
  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<DriverAuthBloc>().add(DriverAuthLoginRequested(
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final t = lang.t;

    return BlocListener<DriverAuthBloc, DriverAuthState>(
      listener: (ctx, state) {
        if (state is DriverAuthAuthenticated) ctx.go('/dashboard');
        if (state is DriverAuthPending) ctx.go('/pending');
        if (state is DriverAuthFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: Directionality(
        textDirection: lang.textDirection,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),
                    const DossLogo(size: 40),
                    const SizedBox(height: 10),
                    // Driver badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: const Text('Driver App',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ),
                    const SizedBox(height: 36),

                    Text(t('Drive with DOSS', 'اقود مع DOSS'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(t('Earn more, keep 100%', 'اكسب أكثر، احتفظ بـ 100%'),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 34),

                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white),
                      decoration: AppTheme.inputDecoration(
                        label: t('Phone number', 'رقم الهاتف'),
                        hint: '01X XXXX XXXX',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t('Phone is required', 'رقم الهاتف مطلوب')
                          : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white),
                      decoration: AppTheme.inputDecoration(
                        label: t('Password', 'كلمة المرور'),
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? t('Password is required', 'كلمة المرور مطلوبة')
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 28),

                    BlocBuilder<DriverAuthBloc, DriverAuthState>(
                      builder: (ctx, state) {
                        final loading = state is DriverAuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.surface,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                : Text(t('Sign In', 'تسجيل الدخول'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(t("Don't have an account? ", 'ليس لديك حساب؟ '),
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13)),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(t('Sign Up', 'إنشاء حساب'),
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    Center(
                      child: TextButton.icon(
                        onPressed: () => lang.toggle(),
                        icon: const Icon(Icons.language,
                            color: AppTheme.textMuted, size: 15),
                        label: Text(lang.isArabic ? 'English' : 'العربية',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 24),
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
