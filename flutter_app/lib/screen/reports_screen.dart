import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../providers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ReportsPage extends StatefulWidget {
  final Function(String) onNavigate;
  const ReportsPage({super.key, required this.onNavigate});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Map<String, dynamic>> _weekData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthController.instance.userId;
    final data = await DatabaseHelper.instance.getWeeklyAdherence(uid);
    setState(() {
      _weekData = data;
      _loading = false;
    });
  }

  double get _weeklyRate {
    if (_weekData.isEmpty) return 0;
    final total =
        _weekData.fold<int>(0, (s, d) => s + (d['total'] as int));
    final taken =
        _weekData.fold<int>(0, (s, d) => s + (d['taken'] as int));
    return total > 0 ? taken / total : 0.0;
  }

  int get _totalTaken =>
      _weekData.fold<int>(0, (s, d) => s + (d['taken'] as int));
  int get _totalMissed {
    final total =
        _weekData.fold<int>(0, (s, d) => s + (d['total'] as int));
    return total - _totalTaken;
  }

  String get _motivationText {
    final r = _weeklyRate;
    if (r >= 0.9) return 'Você está arrasando! 🎉';
    if (r >= 0.7) return 'Bom progresso! Continue assim.';
    if (r >= 0.5) return 'Você pode melhorar. Não desista!';
    return 'Atenção com seu tratamento.';
  }

  @override
  Widget build(BuildContext context) {
    final ratePercent = (_weeklyRate * 100).round();

    return Container(
      color: AppTheme.blue,
      child: Column(
        children: [
          const StatusBarWidget(dark: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Relatórios',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Veja seu progresso e estatísticas',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.refresh,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.green))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // ── Adherence circle card ──────
                                  _AdherenceCard(
                                    rate: _weeklyRate,
                                    ratePercent: ratePercent,
                                    motivationText: _motivationText,
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Bar chart ─────────────────
                                  const Text('Adesão dos últimos 7 dias',
                                      style: TextStyle(
                                          color: AppTheme.textMid,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: AppTheme.bg,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: _weekData.isEmpty
                                        ? const Center(
                                            child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text(
                                                'Sem dados ainda',
                                                style: TextStyle(
                                                    color: AppTheme
                                                        .textLight)),
                                          ))
                                        : SizedBox(
                                            height: 160,
                                            child: CustomPaint(
                                              size: const Size(
                                                  double.infinity, 160),
                                              painter: BarChartPainter(
                                                values: _weekData
                                                    .map((d) =>
                                                        (d['rate'] as double) *
                                                        100)
                                                    .toList(),
                                                labels: _weekData
                                                    .map((d) =>
                                                        d['label'] as String)
                                                    .toList(),
                                                colors: _weekData
                                                    .map((d) =>
                                                        (d['rate'] as double) >=
                                                                0.8
                                                            ? AppTheme.green
                                                            : (d['rate']
                                                                        as double) >=
                                                                    0.5
                                                                ? AppTheme.amber
                                                                : AppTheme.red)
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Stats grid ────────────────
                                  const Text('Estatísticas da semana',
                                      style: TextStyle(
                                          color: AppTheme.textMid,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: _StatCard(
                                        icon: Icons.check_circle_outline,
                                        iconColor: AppTheme.green,
                                        bg: const Color(0xFFF0FDF4),
                                        value: '$_totalTaken',
                                        label: 'Doses\ntomadas',
                                      )),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _StatCard(
                                        icon: Icons.cancel_outlined,
                                        iconColor: AppTheme.red,
                                        bg: const Color(0xFFFEF2F2),
                                        value: '$_totalMissed',
                                        label: 'Doses\nnão tomadas',
                                      )),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: _StatCard(
                                        icon: Icons.percent,
                                        iconColor: AppTheme.blue,
                                        bg: const Color(0xFFEFF6FF),
                                        value: '$ratePercent%',
                                        label: 'Taxa de\nadesão',
                                      )),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Daily breakdown ───────────
                                  if (_weekData.isNotEmpty) ...[
                                    const Text('Detalhes por dia',
                                        style: TextStyle(
                                            color: AppTheme.textMid,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 12),
                                    ..._weekData.map((d) =>
                                        _DayRow(day: d)),
                                  ],

                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                  ),
                  BottomNavigation(
                      active: 'reports',
                      onNavigate: widget.onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adherence circle card ────────────────────────────────────
class _AdherenceCard extends StatelessWidget {
  final double rate;
  final int ratePercent;
  final String motivationText;

  const _AdherenceCard({
    required this.rate,
    required this.ratePercent,
    required this.motivationText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.green.withOpacity(0.12),
            AppTheme.green.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Adesão ao tratamento',
              style: TextStyle(
                  color: AppTheme.textGray, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: CircularProgressPainter(
                        progress: rate,
                        color: rate >= 0.7
                            ? AppTheme.green
                            : rate >= 0.5
                                ? AppTheme.amber
                                : AppTheme.red,
                        strokeWidth: 9,
                      ),
                    ),
                    Center(
                      child: Text(
                        '$ratePercent%',
                        style: TextStyle(
                          color: rate >= 0.7
                              ? AppTheme.green
                              : rate >= 0.5
                                  ? AppTheme.amber
                                  : AppTheme.red,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      motivationText,
                      style: const TextStyle(
                          color: AppTheme.textMid,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Baseado nos seus registros dos últimos 7 dias.',
                      style: TextStyle(
                          color: AppTheme.textGray, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    // Legend
                    _Legend(color: AppTheme.green, label: '≥ 80% Excelente'),
                    _Legend(color: AppTheme.amber, label: '50-79% Regular'),
                    _Legend(color: AppTheme.red, label: '< 50% Atenção'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: AppTheme.textGray)),
        ],
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xFF4B5563))),
        ],
      ),
    );
  }
}

// ── Day row ──────────────────────────────────────────────────
class _DayRow extends StatelessWidget {
  final Map<String, dynamic> day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final rate = (day['rate'] as double);
    final ratePercent = (rate * 100).round();
    final color = rate >= 0.8
        ? AppTheme.green
        : rate >= 0.5
            ? AppTheme.amber
            : rate > 0
                ? AppTheme.red
                : AppTheme.textLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(day['label'] as String,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMid)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate,
                  backgroundColor: AppTheme.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 36,
              child: Text(
                (day['total'] as int) > 0 ? '$ratePercent%' : '-',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
