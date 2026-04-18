import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/common_button.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  final int _total = 4;

  void _next() {
    if (_page < _total - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_page > 0) _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    final ok = await context.read<OnboardingProvider>().submit();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.read<OnboardingProvider>().error ?? 'Error'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(_total, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i <= _page ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      onPressed: _back,
                      color: AppColors.textPrimary,
                    ),
                  const Spacer(),
                  Text('${_page + 1} of $_total',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Page1BasicInfo(),
                  _Page2Activity(),
                  _Page3Health(),
                  _Page4Lifestyle(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Consumer<OnboardingProvider>(
                builder: (_, p, __) => PrimaryButton(
                  label: _page == _total - 1 ? 'Complete setup' : 'Continue',
                  loading: p.loading,
                  onTap: _next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1 ───────────────────────────────────────────────────────────────────
class _Page1BasicInfo extends StatelessWidget {
  const _Page1BasicInfo();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('About you',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Help us personalise your experience',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        _SectionCard(children: [
          _EditableTextField(
            label: 'Full name',
            hint: 'Your name',
            initialValue: p.fullName,
            onChanged: (v) => context.read<OnboardingProvider>().fullName = v,
          ),
          const Divider(height: 1),
          _DropdownRow(
            label: 'Gender',
            value: p.gender,
            items: const ['Male', 'Female', 'Other'],
            onChanged: (v) => context.read<OnboardingProvider>()
              ..gender = v!
              ..notifyListeners(),
          ),
          const Divider(height: 1),
          _SliderRow(
            label: 'Age', value: p.age.toDouble(),
            min: 10, max: 90, unit: 'yrs', isInt: true,
            onChanged: (v) => context.read<OnboardingProvider>()
              ..age = v.round()
              ..notifyListeners(),
          ),
          const Divider(height: 1),
          _SliderRow(
            label: 'Height', value: p.heightCm,
            min: 100, max: 220, unit: 'cm',
            onChanged: (v) => context.read<OnboardingProvider>()
              ..heightCm = v
              ..notifyListeners(),
          ),
          const Divider(height: 1),
          _SliderRow(
            label: 'Weight', value: p.weightKg,
            min: 30, max: 150, unit: 'kg',
            onChanged: (v) => context.read<OnboardingProvider>()
              ..weightKg = v
              ..notifyListeners(),
          ),
        ]),
      ]),
    );
  }
}

// ─── Page 2 ───────────────────────────────────────────────────────────────────
class _Page2Activity extends StatelessWidget {
  const _Page2Activity();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('Activity goals',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Set your daily targets',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        _SectionCard(children: [
          _SliderRow(
            label: 'Daily steps', value: p.dailySteps.toDouble(),
            min: 2000, max: 20000, divisions: 36, unit: 'steps', isInt: true,
            onChanged: (v) => context.read<OnboardingProvider>()
              ..dailySteps = v.round()
              ..notifyListeners(),
          ),
          const Divider(height: 1),
          _DropdownRow(
            label: 'Sitting time/day',
            value: p.sittingTime,
            items: const ['1','2','3','4','5','6','7','8','9','10'],
            suffix: 'hrs',
            onChanged: (v) => context.read<OnboardingProvider>()
              ..sittingTime = v!
              ..notifyListeners(),
          ),
          const Divider(height: 1),
          _DropdownRow(
            label: 'Exercise/week',
            value: p.exerciseFrequency,
            items: const ['0','1','2','3','4','5','6','7'],
            suffix: 'days',
            onChanged: (v) => context.read<OnboardingProvider>()
              ..exerciseFrequency = v!
              ..notifyListeners(),
          ),
          const Divider(height: 1),
          _SliderRow(
            label: 'Sleep duration', value: p.sleepDuration,
            min: 4, max: 12, divisions: 16, unit: 'hrs',
            onChanged: (v) => context.read<OnboardingProvider>()
              ..sleepDuration = v
              ..notifyListeners(),
          ),
        ]),
      ]),
    );
  }
}

// ─── Page 3 ───────────────────────────────────────────────────────────────────
class _Page3Health extends StatelessWidget {
  const _Page3Health();
  static const _conditions = ['None','Diabetes','Hypertension','Asthma','Thyroid','PCOS'];
  static const _history    = ['None','Diabetes','Heart Disease','Cancer','Hypertension'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('Health profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Medical info stays private',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        _SectionCard(children: [
          _SliderRow(
            label: 'Resting heart rate', value: p.restingHeartRate.toDouble(),
            min: 40, max: 120, unit: 'bpm', isInt: true,
            onChanged: (v) => context.read<OnboardingProvider>()
              ..restingHeartRate = v.round()
              ..notifyListeners(),
          ),
        ]),
        const SizedBox(height: 16),
        const _SectionLabel('Medical conditions'),
        const SizedBox(height: 8),
        _ChipGroup(
          options: _conditions,
          selected: p.medicalConditions,
          onToggle: (val) {
            final pr = context.read<OnboardingProvider>();
            final list = List<String>.from(pr.medicalConditions);
            if (val == 'None') { list..clear()..add('None'); }
            else {
              list.remove('None');
              list.contains(val) ? list.remove(val) : list.add(val);
              if (list.isEmpty) list.add('None');
            }
            pr.medicalConditions = list;
            pr.notifyListeners();
          },
        ),
        const SizedBox(height: 16),
        const _SectionLabel('Family history'),
        const SizedBox(height: 8),
        _ChipGroup(
          options: _history,
          selected: p.familyHistory,
          onToggle: (val) {
            final pr = context.read<OnboardingProvider>();
            final list = List<String>.from(pr.familyHistory);
            if (val == 'None') { list..clear()..add('None'); }
            else {
              list.remove('None');
              list.contains(val) ? list.remove(val) : list.add(val);
              if (list.isEmpty) list.add('None');
            }
            pr.familyHistory = list;
            pr.notifyListeners();
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ─── Page 4 ───────────────────────────────────────────────────────────────────
class _Page4Lifestyle extends StatelessWidget {
  const _Page4Lifestyle();
  @override
  Widget build(BuildContext context) {
    final p = context.watch<OnboardingProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const Text('Lifestyle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Helps us calculate your health score',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        _SectionCard(children: [
          _DropdownRow(
            label: 'Smoking', value: p.smoking,
            items: const ['No', 'Occasional', 'Regular'],
            onChanged: (v) => context.read<OnboardingProvider>()
              ..smoking = v!..notifyListeners(),
          ),
          const Divider(height: 1),
          _DropdownRow(
            label: 'Alcohol', value: p.alcohol,
            items: const ['None', 'Occasional', 'Regular'],
            onChanged: (v) => context.read<OnboardingProvider>()
              ..alcohol = v!..notifyListeners(),
          ),
          const Divider(height: 1),
          _DropdownRow(
            label: 'Stress level', value: p.stressLevel,
            items: const ['Low', 'Moderate', 'High'],
            onChanged: (v) => context.read<OnboardingProvider>()
              ..stressLevel = v!..notifyListeners(),
          ),
        ]),
        const SizedBox(height: 24),
        const _SectionLabel('Your location'),
        const SizedBox(height: 4),
        const Text('Enter coordinates for health insights',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        _SectionCard(children: [
          _EditableTextField(
            label: 'Latitude',
            hint: 'e.g. 18.5204',
            initialValue: p.lat == 0 ? '' : p.lat.toString(),
            isNumeric: true,
            prefixIcon: Icons.location_on_outlined,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) context.read<OnboardingProvider>().lat = d;
            },
          ),
          const Divider(height: 1),
          _EditableTextField(
            label: 'Longitude',
            hint: 'e.g. 73.8567',
            initialValue: p.long == 0 ? '' : p.long.toString(),
            isNumeric: true,
            prefixIcon: Icons.explore_outlined,
            onChanged: (v) {
              final d = double.tryParse(v);
              if (d != null) context.read<OnboardingProvider>().long = d;
            },
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF9A825)),
            SizedBox(width: 8),
            Expanded(child: Text(
              'Find coordinates on Google Maps by long-pressing your location.',
              style: TextStyle(fontSize: 12, color: Color(0xFF795548)),
            )),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(children: children),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
}

// ── Stateful text field (fixes the "not editable" issue) ──────────────────────
class _EditableTextField extends StatefulWidget {
  final String label, hint, initialValue;
  final ValueChanged<String> onChanged;
  final bool isNumeric;
  final IconData? prefixIcon;

  const _EditableTextField({
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.onChanged,
    this.isNumeric = false,
    this.prefixIcon,
  });

  @override
  State<_EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<_EditableTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      if (widget.prefixIcon != null) ...[
        Icon(widget.prefixIcon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
      ],
      SizedBox(
        width: widget.prefixIcon != null ? 80 : 110,
        child: Text(widget.label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ),
      Expanded(
        child: TextField(
          controller: _ctrl,
          onChanged: widget.onChanged,
          textAlign: TextAlign.end,
          keyboardType: widget.isNumeric
              ? const TextInputType.numberWithOptions(decimal: true, signed: true)
              : TextInputType.text,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: AppColors.divider),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        ),
      ),
    ]),
  );
}

// ── Stateful slider (fixes the "not moving" issue) ────────────────────────────
class _SliderRow extends StatefulWidget {
  final String label, unit;
  final double value, min, max;
  final int? divisions;
  final bool isInt;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.divisions,
    this.isInt = false,
  });

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(_SliderRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _current = widget.value.clamp(widget.min, widget.max);
    }
  }

  String get _display => widget.isInt
      ? _current.round().toString()
      : _current.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Column(children: [
      Row(children: [
        Text(widget.label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Text('$_display ${widget.unit}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.divider,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withOpacity(0.1),
        ),
        child: Slider(
          value: _current,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          onChanged: (v) {
            setState(() => _current = v);
            widget.onChanged(v);
          },
        ),
      ),
    ]),
  );
}

// ── Dropdown (stateless is fine since provider rebuilds parent) ───────────────
class _DropdownRow extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final String? suffix;
  final ValueChanged<String?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(
              suffix != null ? '$e  $suffix' : e,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          )).toList(),
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    ]),
  );
}

class _ChipGroup extends StatelessWidget {
  final List<String> options, selected;
  final ValueChanged<String> onToggle;
  const _ChipGroup({required this.options, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8, runSpacing: 8,
    children: options.map((o) {
      final active = selected.contains(o);
      return GestureDetector(
        onTap: () => onToggle(o),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.divider,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Text(o, style: TextStyle(
            fontSize: 13,
            color: active ? AppColors.primary : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          )),
        ),
      );
    }).toList(),
  );
}