import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common_button.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _mobile    = TextEditingController();
  final _pin       = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _obscure = true;

  Future<void> _register() async {
    if (_mobile.text.length != 10) {
      _snack('Enter a valid 10-digit mobile number'); return;
    }
    if (_pin.text.length < 4) {
      _snack('PIN must be at least 4 digits'); return;
    }
    if (_pin.text != _confirmPin.text) {
      _snack('PINs do not match'); return;
    }
    final token = await context.read<AuthProvider>()
        .register(_mobile.text.trim(), _pin.text.trim());
    if (!mounted) return;
    if (token != null) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      _snack(context.read<AuthProvider>().error ?? 'Registration failed');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Create account', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              const Text('Start your health journey today',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 36),
              _label('Mobile number'),
              const SizedBox(height: 8),
              _field(_mobile, 'Enter 10-digit number',
                  type: TextInputType.phone, maxLen: 10,
                  prefix: const Icon(Icons.phone_outlined, size: 20, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              _label('Set PIN'),
              const SizedBox(height: 8),
              _field(_pin, '4-digit PIN',
                  obscure: _obscure, maxLen: 6,
                  type: TextInputType.number,
                  prefix: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                  suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: AppColors.textSecondary),
                      onPressed: () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 20),
              _label('Confirm PIN'),
              const SizedBox(height: 8),
              _field(_confirmPin, 'Re-enter PIN',
                  obscure: true, maxLen: 6,
                  type: TextInputType.number,
                  prefix: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary)),
              const SizedBox(height: 36),
              Consumer<AuthProvider>(
                  builder: (_, p, __) => PrimaryButton(
                      label: 'Create account', loading: p.loading, onTap: _register)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, bool obscure = false,
        int? maxLen, Widget? prefix, Widget? suffix}) =>
      TextField(
        controller: ctrl, obscureText: obscure,
        keyboardType: type, maxLength: maxLen,
        decoration: InputDecoration(
          hintText: hint, counterText: '',
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: prefix, suffixIcon: suffix,
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      );
}