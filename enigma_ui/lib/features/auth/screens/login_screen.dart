import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../../../widgets/common_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  final _pin    = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    if (_mobile.text.length != 10 || _pin.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid mobile and 4-digit PIN')));
      return;
    }
    final provider = context.read<AuthProvider>();
    final token = await provider.login(_mobile.text.trim(), _pin.text.trim());
    if (!mounted) return;
    if (token != null) {
      final profileDone = await StorageService.isProfileDone();
      Navigator.pushReplacementNamed(context, profileDone ? '/home' : '/onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Login failed'),
              backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                  child: Text('Welcome back', style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
              const SizedBox(height: 6),
              const Center(
                  child: Text('Sign in to your health dashboard',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
              const SizedBox(height: 44),
              // Mobile field
              _label('Mobile number'),
              const SizedBox(height: 8),
              TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDeco(
                  hint: '10-digit mobile number',
                  prefix: const Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              // PIN field
              _label('PIN'),
              const SizedBox(height: 8),
              TextField(
                controller: _pin,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _inputDeco(
                  hint: '4-digit PIN',
                  prefix: const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Consumer<AuthProvider>(
                builder: (_, p, __) => PrimaryButton(
                  label: 'Sign in',
                  loading: p.loading,
                  onTap: _login,
                ),
              ),
              const SizedBox(height: 16),
              OutlineButton(
                label: 'Create account',
                onTap: () => Navigator.pushNamed(context, '/register'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

  InputDecoration _inputDeco({required String hint, Widget? prefix, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: prefix,
        suffixIcon: suffix,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );
}