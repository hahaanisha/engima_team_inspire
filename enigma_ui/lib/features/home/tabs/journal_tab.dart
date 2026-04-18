import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../provider/home_provider.dart';

class JournalTab extends StatelessWidget {
  const JournalTab({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<HomeProvider>();
    return CustomScrollView(slivers: [
      const SliverAppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        floating: true,
        title: Text('Journal',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildListDelegate([

          // Today's summary
          Container(
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
                _JournalBadge(
                  icon: Icons.directions_walk_rounded,
                  label: '${p.dailySteps} steps goal',
                  color: AppColors.steps,
                ),
              ]),
              const SizedBox(height: 16),
              _JournalMetricRow(
                icon: Icons.bedtime_rounded,
                color: const Color(0xFF7C4DFF),
                label: 'Sleep duration',
                value: '${p.sleepDuration} hrs',
              ),
              const Divider(height: 20),
              _JournalMetricRow(
                icon: Icons.favorite_rounded,
                color: Colors.red,
                label: 'Resting heart rate',
                value: '${p.restingHeartRate} bpm',
              ),
              const Divider(height: 20),
              _JournalMetricRow(
                icon: Icons.psychology_outlined,
                color: Colors.orange,
                label: 'Stress level',
                value: p.stressLevel,
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Insights list
          if (p.insights.isNotEmpty) ...[
            const Text('Health recommendations',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            ...p.insights.asMap().entries.map((e) => _JournalInsightCard(
              index: e.key + 1,
              text: e.value,
            )),
          ],
          const SizedBox(height: 24),
        ])),
      ),
    ]);
  }
}

class _JournalBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _JournalBadge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _JournalMetricRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _JournalMetricRow({
    required this.icon, required this.color,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
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
    Text(value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary)),
  ]);
}

class _JournalInsightCard extends StatelessWidget {
  final int index;
  final String text;
  const _JournalInsightCard({required this.index, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(child: Text('$index',
            style: const TextStyle(color: Colors.white, fontSize: 11,
                fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5))),
    ]),
  );
}