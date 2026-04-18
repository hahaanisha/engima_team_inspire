import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../provider/home_provider.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isEditing = false;

  // Controllers for all editable fields
  late TextEditingController _nameCtrl;
  late TextEditingController _stepsCtrl;
  late TextEditingController _sleepCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heartRateCtrl;
  late TextEditingController _stressCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<HomeProvider>();
    _nameCtrl      = TextEditingController(text: p.fullName);
    _stepsCtrl     = TextEditingController(text: '${p.dailySteps}');
    _sleepCtrl     = TextEditingController(text: '${p.sleepDuration}');
    _heightCtrl    = TextEditingController(text: '${p.heightCm.toInt()}');
    _weightCtrl    = TextEditingController(text: '${p.weightKg.toInt()}');
    _heartRateCtrl = TextEditingController(text: '${p.restingHeartRate}');
    _stressCtrl    = TextEditingController(text: p.stressLevel);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stepsCtrl.dispose();
    _sleepCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _heartRateCtrl.dispose();
    _stressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final p = context.read<HomeProvider>();

    // Parse & validate numbers; fall back to current value on bad input
    final steps     = int.tryParse(_stepsCtrl.text)    ?? p.dailySteps;
    final sleep     = double.tryParse(_sleepCtrl.text) ?? p.sleepDuration;
    final height    = double.tryParse(_heightCtrl.text) ?? p.heightCm;
    final weight    = double.tryParse(_weightCtrl.text) ?? p.weightKg;
    final heartRate = int.tryParse(_heartRateCtrl.text) ?? p.restingHeartRate;

    // Update fullName directly (not in updateProfile signature)
    p.fullName = _nameCtrl.text.trim();

    // Update remaining fields via provider (also persists to storage internally)
    await p.updateProfile(
      heightCm:         height,
      weightKg:         weight,
      dailySteps:       steps,
      sleepDuration:    sleep,
      restingHeartRate: heartRate,
      stressLevel:      _stressCtrl.text.trim(),
    );

    // Also persist fullName to storage (snake_case key matches StorageService)
    final existing = await StorageService.getProfileData();
    existing['full_name'] = _nameCtrl.text.trim();
    await StorageService.saveProfileData(existing);

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile saved'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _cancelEditing() {
    // Reset controllers to current provider values
    final p = context.read<HomeProvider>();
    _nameCtrl.text      = p.fullName;
    _stepsCtrl.text     = '${p.dailySteps}';
    _sleepCtrl.text     = '${p.sleepDuration}';
    _heightCtrl.text    = '${p.heightCm.toInt()}';
    _weightCtrl.text    = '${p.weightKg.toInt()}';
    _heartRateCtrl.text = '${p.restingHeartRate}';
    _stressCtrl.text    = p.stressLevel;
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HomeProvider>();

    return CustomScrollView(slivers: [
      SliverAppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        floating: true,
        title: const Text('Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save',
                  style: TextStyle(color: AppColors.primary,
                      fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit profile',
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.textSecondary),
              onPressed: () async {
                await StorageService.clear();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ],
      ),

      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildListDelegate([

            // ── Avatar + name ───────────────────────────────────────────────
            Center(child: Column(children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primary,
                child: Text(
                  p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 28, color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),

              // Editable name
              if (_isEditing)
                SizedBox(
                  width: 220,
                  child: _InlineTextField(
                    controller: _nameCtrl,
                    label: 'Full name',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                )
              else
                Text(p.fullName.isNotEmpty ? p.fullName : 'Your name',
                    style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),

              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Health score: ${p.healthScore} · ${p.category}',
                    style: const TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ])),
            const SizedBox(height: 24),

            // ── Activity goals ───────────────────────────────────────────────
            const _ProfileSectionTitle('Activity goals'),
            const SizedBox(height: 10),
            _ProfileCard(rows: [
              _ProfileRow(
                icon: Icons.directions_walk_rounded,
                label: 'Daily steps goal',
                color: AppColors.steps,
                isEditing: _isEditing,
                controller: _stepsCtrl,
                value: '${p.dailySteps}',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _ProfileRow(
                icon: Icons.bedtime_rounded,
                label: 'Sleep duration',
                color: const Color(0xFF7C4DFF),
                isEditing: _isEditing,
                controller: _sleepCtrl,
                value: '${p.sleepDuration} hrs',
                suffix: 'hrs',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ]),
            const SizedBox(height: 16),

            // ── Body metrics ─────────────────────────────────────────────────
            const _ProfileSectionTitle('Body metrics'),
            const SizedBox(height: 10),
            _ProfileCard(rows: [
              _ProfileRow(
                icon: Icons.straighten_rounded,
                label: 'Height',
                color: AppColors.primary,
                isEditing: _isEditing,
                controller: _heightCtrl,
                value: '${p.heightCm.toInt()} cm',
                suffix: 'cm',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _ProfileRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                color: AppColors.primary,
                isEditing: _isEditing,
                controller: _weightCtrl,
                value: '${p.weightKg.toInt()} kg',
                suffix: 'kg',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (p.bmi > 0)
                _ProfileRow(
                  icon: Icons.calculate_outlined,
                  label: 'BMI',
                  color: _bmiColor(p.bmi),
                  isEditing: false, // BMI is calculated, not editable
                  controller: TextEditingController(),
                  value: p.bmi.toStringAsFixed(1),
                ),
            ]),
            const SizedBox(height: 16),

            // ── Vitals ────────────────────────────────────────────────────────
            const _ProfileSectionTitle('Vitals'),
            const SizedBox(height: 10),
            _ProfileCard(rows: [
              _ProfileRow(
                icon: Icons.favorite_rounded,
                label: 'Resting heart rate',
                color: Colors.red,
                isEditing: _isEditing,
                controller: _heartRateCtrl,
                value: '${p.restingHeartRate} bpm',
                suffix: 'bpm',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _ProfileRow(
                icon: Icons.psychology_outlined,
                label: 'Stress level',
                color: Colors.orange,
                isEditing: _isEditing,
                controller: _stressCtrl,
                value: p.stressLevel,
                keyboardType: TextInputType.text,
              ),
            ]),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    ]);
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25)   return AppColors.heartPts;
    if (bmi < 30)   return Colors.orange;
    return Colors.red;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileSectionTitle extends StatelessWidget {
  final String text;
  const _ProfileSectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
          color: AppColors.textSecondary));
}

class _ProfileCard extends StatelessWidget {
  final List<_ProfileRow> rows;
  const _ProfileCard({required this.rows});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(
      children: rows.asMap().entries.map((e) => Column(children: [
        e.value,
        if (e.key < rows.length - 1) const Divider(height: 1, indent: 52),
      ])).toList(),
    ),
  );
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool isEditing;
  final TextEditingController controller;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isEditing,
    required this.controller,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: isEditing ? 8 : 14),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),

      if (isEditing)
        SizedBox(
          width: 90,
          child: _InlineTextField(
            controller: controller,
            suffix: suffix,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.right,
          ),
        )
      else
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
    ]),
  );
}

/// A minimal inline text field that blends into the card style
class _InlineTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;

  const _InlineTextField({
    required this.controller,
    this.label,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
    textAlign: textAlign,
    style: style ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
    decoration: InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      suffixText: suffix,
      suffixStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.primary.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
    ),
  );
}