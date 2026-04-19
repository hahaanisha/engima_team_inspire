import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../provider/home_provider.dart';

// ─── Avatar config ────────────────────────────────────────────────────────────
const List<_AvatarStyle> _kAvatarStyles = [
  _AvatarStyle(bg: Color(0xFFFFFC00), fg: Color(0xFF1A1A1A), emoji: '😎'),
  _AvatarStyle(bg: Color(0xFFFF6B6B), fg: Colors.white,      emoji: '🔥'),
  _AvatarStyle(bg: Color(0xFF4ECDC4), fg: Colors.white,      emoji: '🌊'),
  _AvatarStyle(bg: Color(0xFFA29BFE), fg: Colors.white,      emoji: '✨'),
  _AvatarStyle(bg: Color(0xFF55EFC4), fg: Color(0xFF1A1A1A), emoji: '🌿'),
  _AvatarStyle(bg: Color(0xFFFD79A8), fg: Colors.white,      emoji: '💫'),
  _AvatarStyle(bg: Color(0xFF0984E3), fg: Colors.white,      emoji: '⚡'),
  _AvatarStyle(bg: Color(0xFFE17055), fg: Colors.white,      emoji: '🎯'),
  _AvatarStyle(bg: Color(0xFF00B894), fg: Colors.white,      emoji: '🏃'),
  _AvatarStyle(bg: Color(0xFF6C5CE7), fg: Colors.white,      emoji: '🧬'),
  _AvatarStyle(bg: Color(0xFFFEEAA7), fg: Color(0xFF1A1A1A), emoji: '⭐'),
  _AvatarStyle(bg: Color(0xFFDFE6E9), fg: Color(0xFF2D3436), emoji: '🤖'),
];

class _AvatarStyle {
  final Color bg, fg;
  final String emoji;
  const _AvatarStyle({required this.bg, required this.fg, required this.emoji});
}

// ─── Main ProfileTab ──────────────────────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isEditing = false;
  int _avatarIndex = 0;

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
    _loadAvatarIndex();
  }

  Future<void> _loadAvatarIndex() async {
    final data = await StorageService.getProfileData();
    if (mounted) {
      setState(() {
        _avatarIndex = (data['avatar_index'] ?? 0) as int;
      });
    }
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

    final steps     = int.tryParse(_stepsCtrl.text)     ?? p.dailySteps;
    final sleep     = double.tryParse(_sleepCtrl.text)  ?? p.sleepDuration;
    final height    = double.tryParse(_heightCtrl.text) ?? p.heightCm;
    final weight    = double.tryParse(_weightCtrl.text) ?? p.weightKg;
    final heartRate = int.tryParse(_heartRateCtrl.text) ?? p.restingHeartRate;

    p.fullName = _nameCtrl.text.trim();

    await p.updateProfile(
      heightCm:         height,
      weightKg:         weight,
      dailySteps:       steps,
      sleepDuration:    sleep,
      restingHeartRate: heartRate,
      stressLevel:      _stressCtrl.text.trim(),
    );

    final existing = await StorageService.getProfileData();
    existing['full_name']    = _nameCtrl.text.trim();
    existing['avatar_index'] = _avatarIndex;
    await StorageService.saveProfileData(existing);

    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile saved'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _cancelEditing() {
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

  void _openAvatarPicker() {
    final initials = context.read<HomeProvider>().fullName.isNotEmpty
        ? context.read<HomeProvider>().fullName[0].toUpperCase()
        : 'A';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AvatarPickerSheet(
        currentIndex: _avatarIndex,
        initials: initials,
        onSelected: (i) async {
          setState(() => _avatarIndex = i);
          final existing = await StorageService.getProfileData();
          existing['avatar_index'] = i;
          await StorageService.saveProfileData(existing);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HomeProvider>();
    final style = _kAvatarStyles[_avatarIndex % _kAvatarStyles.length];
    final initials = p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'A';

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
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
              onPressed: () async {
                await StorageService.clear();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ],
      ),

      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildListDelegate([

          // ── Snapchat-style avatar header ──────────────────────────────
          _AvatarHeader(
            style: style,
            initials: initials,
            fullName: p.fullName,
            healthScore: p.healthScore,
            category: p.category,
            isEditing: _isEditing,
            nameController: _nameCtrl,
            onAvatarTap: _openAvatarPicker,
          ),
          const SizedBox(height: 28),

          // ── Activity goals ────────────────────────────────────────────
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

          // ── Body metrics ──────────────────────────────────────────────
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
                isEditing: false,
                controller: TextEditingController(),
                value: p.bmi.toStringAsFixed(1),
              ),
          ]),
          const SizedBox(height: 16),

          // ── Vitals ────────────────────────────────────────────────────
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
        ])),
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

// ─── Snapchat-style Avatar Header ────────────────────────────────────────────
class _AvatarHeader extends StatelessWidget {
  final _AvatarStyle style;
  final String initials, fullName, category;
  final int healthScore;
  final bool isEditing;
  final TextEditingController nameController;
  final VoidCallback onAvatarTap;

  const _AvatarHeader({
    required this.style,
    required this.initials,
    required this.fullName,
    required this.healthScore,
    required this.category,
    required this.isEditing,
    required this.nameController,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Gradient glow ring
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      style.bg,
                      Color.lerp(style.bg, Colors.white, 0.4)!,
                      style.bg.withOpacity(0.7),
                      style.bg,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: style.bg.withOpacity(0.45),
                      blurRadius: 22,
                      spreadRadius: 3,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // White separator ring
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              // Avatar face
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: style.bg,
                ),
                child: Center(
                  child: Text(style.emoji,
                      style: const TextStyle(fontSize: 36)),
                ),
              ),
              // Camera badge
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12),
                          blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      size: 14, color: Color(0xFF2D3436)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (isEditing)
          SizedBox(
            width: 220,
            child: _InlineTextField(
              controller: nameController,
              label: 'Full name',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          )
        else
          Text(
            fullName.isNotEmpty ? fullName : 'Your name',
            style: const TextStyle(fontSize: 20,
                fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),

        const SizedBox(height: 6),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Health score: $healthScore · $category',
              style: const TextStyle(fontSize: 13, color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ),

        const SizedBox(height: 8),
        Text('Tap to change avatar style',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
      ]),
    );
  }
}

// ─── Avatar Picker Bottom Sheet ───────────────────────────────────────────────
class _AvatarPickerSheet extends StatefulWidget {
  final int currentIndex;
  final String initials;
  final ValueChanged<int> onSelected;

  const _AvatarPickerSheet({
    required this.currentIndex,
    required this.initials,
    required this.onSelected,
  });

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final s = _kAvatarStyles[_selected % _kAvatarStyles.length];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 4),

        // Live preview
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: s.bg,
            boxShadow: [BoxShadow(color: s.bg.withOpacity(0.5),
                blurRadius: 18, spreadRadius: 2, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: Text(s.emoji, style: const TextStyle(fontSize: 36)),
          ),
        ),

        const SizedBox(height: 16),
        const Text('Choose your style',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436))),
        const SizedBox(height: 16),

        // 4-column grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _kAvatarStyles.length,
          itemBuilder: (_, i) {
            final av = _kAvatarStyles[i];
            final picked = i == _selected;
            return GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: av.bg,
                  border: Border.all(
                    color: picked ? const Color(0xFF2D3436) : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: picked
                      ? [BoxShadow(color: av.bg.withOpacity(0.6),
                      blurRadius: 12, spreadRadius: 1)]
                      : [],
                ),
                child: Center(
                  child: Text(av.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Apply — Snapchat yellow
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              widget.onSelected(_selected);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFC00),
              foregroundColor: const Color(0xFF1A1A1A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Apply',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

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