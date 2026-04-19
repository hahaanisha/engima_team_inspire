import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/storage_service.dart';
import '../../home/provider/home_provider.dart';
import 'dart:math' as math;

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (_, p, __) {
      if (p.loading) return const Center(child: CircularProgressIndicator());
      return RefreshIndicator(
        onRefresh: p.init,
        child: CustomScrollView(slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello, ${p.fullName.isNotEmpty ? p.fullName.split(' ').first : 'there'}!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const Text('Your health today',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ]),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                tooltip: 'Log out',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Log out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    await StorageService.clear();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  radius: 18,
                  child: Text(
                    p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _ScoreRing(score: p.healthScore, category: p.category),
              const SizedBox(height: 16),
              Row(children: [
                _StatChip(icon: Icons.directions_walk_rounded, label: 'Steps goal',
                    value: p.dailySteps.toString(), color: AppColors.steps),
                const SizedBox(width: 10),
                _StatChip(icon: Icons.bedtime_rounded, label: 'Sleep',
                    value: '${p.sleepDuration}h', color: const Color(0xFF7C4DFF)),
                const SizedBox(width: 10),
                _StatChip(icon: Icons.favorite_rounded, label: 'Heart rate',
                    value: '${p.restingHeartRate}', color: Colors.red),
              ]),
              const SizedBox(height: 16),
              if (p.breakdown.isNotEmpty) ...[
                _SectionHeader('Score breakdown'),
                const SizedBox(height: 10),
                _BreakdownCard(breakdown: p.breakdown),
                const SizedBox(height: 16),
              ],
              if (p.risks.isNotEmpty) ...[
                _SectionHeader('Risk indicators'),
                const SizedBox(height: 10),
                _RiskCard(risks: p.risks),
                const SizedBox(height: 16),
              ],
              if (p.insights.isNotEmpty) ...[
                _SectionHeader('Insights for you'),
                const SizedBox(height: 10),
                ...p.insights.map((ins) => _InsightTile(text: ins)),
              ],
              const SizedBox(height: 24),
            ])),
          ),
        ]),
      );
    });
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final String category;
  const _ScoreRing({required this.score, required this.category});
  Color get _color {
    if (score >= 80) return AppColors.heartPts;
    if (score >= 60) return AppColors.primary;
    return Colors.orange;
  }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.divider)),
    child: Row(children: [
      SizedBox(width: 100, height: 100,
          child: CustomPaint(painter: _RingPainter(score / 100, _color),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$score', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _color)),
                const Text('score', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])))),
      const SizedBox(width: 20),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(category, style: TextStyle(color: _color, fontWeight: FontWeight.w600, fontSize: 14))),
        const SizedBox(height: 8),
        const Text('Your digital health twin score based on activity, sleep, vitals and lifestyle.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
      ])),
    ]),
  );
}

class _RingPainter extends CustomPainter {
  final double progress; final Color color;
  const _RingPainter(this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width/2, cy = size.height/2, r = size.width/2 - 8;
    canvas.drawCircle(Offset(cx,cy), r, Paint()..color=AppColors.divider..style=PaintingStyle.stroke..strokeWidth=10..strokeCap=StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx,cy), radius: r), -math.pi/2, 2*math.pi*progress, false,
        Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=10..strokeCap=StrokeCap.round);
  }
  @override bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class _StatChip extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
    child: Column(children: [
      Icon(icon, color: color, size: 22), const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
    ]),
  ));
}

class _BreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _BreakdownCard({required this.breakdown});
  static const _maxes = {'activity':25,'bmi':25,'heart':15,'lifestyle':15,'sleep':15,'stress':10};
  static const _icons = {'activity':Icons.directions_walk_rounded,'bmi':Icons.monitor_weight_outlined,
    'heart':Icons.favorite_rounded,'lifestyle':Icons.spa_outlined,'sleep':Icons.bedtime_rounded,'stress':Icons.psychology_outlined};
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Column(children: breakdown.entries.map((e) {
      final max = _maxes[e.key] ?? 20; final val = (e.value as num).toInt(); final pct = val/max;
      return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: [
        Row(children: [
          Icon(_icons[e.key] ?? Icons.circle, size: 16, color: AppColors.primary), const SizedBox(width: 8),
          Expanded(child: Text(e.key[0].toUpperCase()+e.key.substring(1), style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
          Text('$val / $max', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct.clamp(0.0,1.0), minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(pct > 0.7 ? AppColors.heartPts : AppColors.primary))),
      ]));
    }).toList()),
  );
}

class _RiskCard extends StatelessWidget {
  final Map<String, dynamic> risks;
  const _RiskCard({required this.risks});
  Color _riskColor(String level) {
    switch (level.toLowerCase()) { case 'high': return Colors.red; case 'medium': return Colors.orange; default: return AppColors.heartPts; }
  }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Row(children: risks.entries.map((e) => Expanded(child: Column(children: [
      Text(e.key[0].toUpperCase()+e.key.substring(1), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _riskColor(e.value).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _riskColor(e.value)))),
    ]))).toList()),
  );
}

class _InsightTile extends StatelessWidget {
  final String text;
  const _InsightTile({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 32, height: 32,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.primary)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5))),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title; const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
}