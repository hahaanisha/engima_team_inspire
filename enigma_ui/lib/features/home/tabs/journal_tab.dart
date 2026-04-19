import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../provider/home_provider.dart';

// ─── Log entry model ──────────────────────────────────────────────────────────
class _LogEntry {
  final String id;
  final String type;   // 'activity' | 'vitals' | 'weight' | 'note'
  final String title;
  final String subtitle;
  final DateTime time;

  _LogEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'subtitle': subtitle,
    'time': time.toIso8601String(),
  };

  factory _LogEntry.fromJson(Map<String, dynamic> j) => _LogEntry(
    id: j['id'],
    type: j['type'],
    title: j['title'],
    subtitle: j['subtitle'],
    time: DateTime.parse(j['time']),
  );
}

// ─── JournalTab ───────────────────────────────────────────────────────────────
class JournalTab extends StatefulWidget {
  const JournalTab({super.key});
  @override
  State<JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<JournalTab> {
  List<_LogEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final data = await StorageService.getProfileData();
    final raw = data['journal_entries'];
    if (raw != null) {
      final list = List<Map<String, dynamic>>.from(
          (jsonDecode(raw as String) as List).map((e) => Map<String, dynamic>.from(e)));
      setState(() {
        _entries = list.map(_LogEntry.fromJson).toList()
          ..sort((a, b) => b.time.compareTo(a.time));
      });
    }
  }

  Future<void> _saveEntries() async {
    final data = await StorageService.getProfileData();
    data['journal_entries'] = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await StorageService.saveProfileData(data);
  }

  void _addEntry(_LogEntry entry) {
    setState(() {
      _entries.insert(0, entry);
    });
    _saveEntries();
  }

  void _deleteEntry(String id) {
    setState(() => _entries.removeWhere((e) => e.id == id));
    _saveEntries();
  }

  // Group entries: today vs yesterday vs older
  Map<String, List<_LogEntry>> get _grouped {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final Map<String, List<_LogEntry>> g = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };
    for (final e in _entries) {
      if (e.time.isAfter(todayStart)) {
        g['Today']!.add(e);
      } else if (e.time.isAfter(yesterdayStart)) {
        g['Yesterday']!.add(e);
      } else {
        g['Earlier']!.add(e);
      }
    }
    return g;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HomeProvider>();
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(slivers: [
        const SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          floating: true,
          title: Text('Journal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(delegate: SliverChildListDelegate([

            // ── Today's summary card ────────────────────────────────────
            _TodaySummaryCard(p: p),
            const SizedBox(height: 24),

            // ── Log entries grouped by day ──────────────────────────────
            for (final group in grouped.entries)
              if (group.value.isNotEmpty) ...[
                _GroupHeader(label: group.key),
                const SizedBox(height: 8),
                ...group.value.map((e) => _EntryCard(
                  entry: e,
                  onDelete: () => _deleteEntry(e.id),
                )),
                const SizedBox(height: 16),
              ],

            if (_entries.isEmpty)
              _EmptyState(onAdd: () => _showAddSheet(context)),
          ])),
        ),
      ]),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddLogSheet(onAdd: _addEntry),
    );
  }
}

// ─── Today summary card ───────────────────────────────────────────────────────
class _TodaySummaryCard extends StatelessWidget {
  final HomeProvider p;
  const _TodaySummaryCard({required this.p});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Today',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const Spacer(),
        _Badge(icon: Icons.directions_walk_rounded,
            label: '${p.dailySteps} steps', color: AppColors.steps),
      ]),
      const SizedBox(height: 16),
      _MetricRow(icon: Icons.bedtime_rounded, color: const Color(0xFF7C4DFF),
          label: 'Sleep', value: '${p.sleepDuration} hrs'),
      const Divider(height: 20),
      _MetricRow(icon: Icons.favorite_rounded, color: Colors.red,
          label: 'Resting heart rate', value: '${p.restingHeartRate} bpm'),
      const Divider(height: 20),
      _MetricRow(icon: Icons.psychology_outlined, color: Colors.orange,
          label: 'Stress level', value: p.stressLevel),
    ]),
  );
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _MetricRow({required this.icon, required this.color,
    required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 36, height: 36,
      decoration: BoxDecoration(color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 18, color: color),
    ),
    const SizedBox(width: 12),
    Expanded(child: Text(label,
        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
    Text(value, style: const TextStyle(fontSize: 14,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  ]);
}

// ─── Group header ─────────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary));
}

// ─── Entry card ───────────────────────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final _LogEntry entry;
  final VoidCallback onDelete;
  const _EntryCard({required this.entry, required this.onDelete});

  static const _typeConfig = {
    'activity': (Icons.directions_run_rounded, Color(0xFF0984E3)),
    'vitals':   (Icons.favorite_rounded,       Colors.red),
    'weight':   (Icons.monitor_weight_outlined, Color(0xFF00B894)),
    'note':     (Icons.edit_note_rounded,       Color(0xFF6C5CE7)),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _typeConfig[entry.type] ??
        (Icons.circle_outlined, AppColors.primary as Color);
    final icon  = cfg.$1 as IconData;
    final color = cfg.$2 as Color;

    final timeStr =
        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.title,
                  style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (entry.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(entry.subtitle,
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ],
          )),
          Text(timeStr,
              style: const TextStyle(fontSize: 12,
                  color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(children: [
      const SizedBox(height: 40),
      Icon(Icons.edit_note_rounded, size: 56, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('No logs yet',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: Colors.grey.shade400)),
      const SizedBox(height: 6),
      Text('Tap + to log your first entry',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      const SizedBox(height: 20),
      TextButton(
        onPressed: onAdd,
        child: const Text('Add entry'),
      ),
    ]),
  );
}

// ─── Add Log bottom sheet ─────────────────────────────────────────────────────
class _AddLogSheet extends StatefulWidget {
  final ValueChanged<_LogEntry> onAdd;
  const _AddLogSheet({required this.onAdd});

  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  String _type = 'activity';

  // activity fields
  final _activityCtrl  = TextEditingController();
  final _durationCtrl  = TextEditingController();
  final _distanceCtrl  = TextEditingController();

  // vitals fields
  final _hrCtrl        = TextEditingController();
  final _bpCtrl        = TextEditingController();
  final _stressCtrl    = TextEditingController();

  // weight field
  final _weightCtrl    = TextEditingController();

  // note field
  final _noteCtrl      = TextEditingController();

  @override
  void dispose() {
    for (final c in [_activityCtrl, _durationCtrl, _distanceCtrl,
      _hrCtrl, _bpCtrl, _stressCtrl, _weightCtrl, _noteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  static const _types = [
    ('activity', Icons.directions_run_rounded,  'Activity',       Color(0xFF0984E3)),
    ('vitals',   Icons.favorite_rounded,         'Vitals',         Colors.red),
    ('weight',   Icons.monitor_weight_outlined,  'Weight',         Color(0xFF00B894)),
    ('note',     Icons.edit_note_rounded,        'Note',           Color(0xFF6C5CE7)),
  ];

  void _submit() {
    String title = '';
    String subtitle = '';

    switch (_type) {
      case 'activity':
        if (_activityCtrl.text.trim().isEmpty) return;
        title = _activityCtrl.text.trim();
        final parts = <String>[];
        if (_distanceCtrl.text.isNotEmpty) parts.add('${_distanceCtrl.text} km');
        if (_durationCtrl.text.isNotEmpty) parts.add('${_durationCtrl.text} min');
        subtitle = parts.join(' · ');
        break;
      case 'vitals':
        title = 'Vitals logged';
        final parts = <String>[];
        if (_hrCtrl.text.isNotEmpty)     parts.add('HR: ${_hrCtrl.text} bpm');
        if (_bpCtrl.text.isNotEmpty)     parts.add('BP: ${_bpCtrl.text}');
        if (_stressCtrl.text.isNotEmpty) parts.add('Stress: ${_stressCtrl.text}');
        if (parts.isEmpty) return;
        subtitle = parts.join(' · ');
        break;
      case 'weight':
        if (_weightCtrl.text.isEmpty) return;
        title = 'Weight';
        subtitle = '${_weightCtrl.text} kg';
        break;
      case 'note':
        if (_noteCtrl.text.trim().isEmpty) return;
        title = _noteCtrl.text.trim();
        subtitle = '';
        break;
    }

    widget.onAdd(_LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type,
      title: title,
      subtitle: subtitle,
      time: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Log entry',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 16),

          // Type selector
          Row(children: _types.map((t) {
            final selected = _type == t.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = t.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? t.$4.withOpacity(0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? t.$4 : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(children: [
                    Icon(t.$2, size: 20,
                        color: selected ? t.$4 : Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text(t.$3,
                        style: TextStyle(fontSize: 11,
                            color: selected ? t.$4 : Colors.grey.shade400,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Fields
          if (_type == 'activity') ...[
            _Field(ctrl: _activityCtrl, label: 'Activity name (e.g. Morning walk)'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _Field(ctrl: _distanceCtrl, label: 'Distance (km)',
                  type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _Field(ctrl: _durationCtrl, label: 'Duration (min)',
                  type: TextInputType.number)),
            ]),
          ] else if (_type == 'vitals') ...[
            _Field(ctrl: _hrCtrl, label: 'Heart rate (bpm)',
                type: TextInputType.number),
            const SizedBox(height: 10),
            _Field(ctrl: _bpCtrl, label: 'Blood pressure (e.g. 120/80)'),
            const SizedBox(height: 10),
            _Field(ctrl: _stressCtrl, label: 'Stress level (e.g. Low)'),
          ] else if (_type == 'weight') ...[
            _Field(ctrl: _weightCtrl, label: 'Weight (kg)',
                type: TextInputType.number),
          ] else ...[
            _Field(ctrl: _noteCtrl, label: 'What\'s on your mind?',
                maxLines: 3),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save entry',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  final int maxLines;
  const _Field({required this.ctrl, required this.label,
    this.type = TextInputType.text, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    maxLines: maxLines,
    style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
  );
}