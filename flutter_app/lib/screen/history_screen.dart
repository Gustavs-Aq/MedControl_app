import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HistoryPage extends StatefulWidget {
  final Function(String) onNavigate;
  const HistoryPage({super.key, required this.onNavigate});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _selectedDate;
  List<HistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _load();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = AuthController.instance.userId;
    final rows = await DatabaseHelper.instance
        .getHistoryByDate(uid, _fmt(_selectedDate));
    setState(() {
      _entries = rows.map(HistoryEntry.fromJson).toList();
      _loading = false;
    });
  }

  void _selectDay(DateTime d) {
    setState(() => _selectedDate = d);
    _load();
  }

  // ── Build 7 days row ─────────────────────────────────────
  List<DateTime> get _weekDays {
    final now = DateTime.now();
    // Mostra a semana atual (seg a dom)
    final weekday = now.weekday; // 1=seg ... 7=dom
    final monday = now.subtract(Duration(days: weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  static const _dayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  // ── Stats do dia ─────────────────────────────────────────
  int get _taken => _entries.where((e) => e.isTaken).length;
  int get _missed => _entries.where((e) => e.isMissed).length;
  int get _late => _entries.where((e) => e.isLate).length;

  String _dateLabel() {
    final months = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    final days = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
      'Sexta-feira', 'Sábado', 'Domingo'
    ];
    return '${days[_selectedDate.weekday - 1]}, '
        '${_selectedDate.day} de ${months[_selectedDate.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.green,
      child: Column(
        children: [
          const StatusBarWidget(dark: true),
          // ── Top header ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Histórico',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('Acompanhe o uso dos seus medicamentos',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 18),
                // ── Week picker ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekDays.asMap().entries.map((e) {
                    final idx = e.key;
                    final day = e.value;
                    final isSelected = _fmt(day) == _fmt(_selectedDate);
                    final isToday = _fmt(day) ==
                        _fmt(DateTime.now());
                    return GestureDetector(
                      onTap: () => _selectDay(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(_dayLabels[idx],
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? AppTheme.green
                                        : Colors.white70)),
                            const SizedBox(height: 2),
                            Text('${day.day}',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.green
                                        : Colors.white)),
                            if (isToday && !isSelected)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(_dateLabel(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // ── White card area ───────────────────────────
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
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  24, 24, 24, 0),
                              children: [
                                // Summary card
                                if (_entries.isNotEmpty)
                                  _SummaryCard(
                                      taken: _taken,
                                      missed: _missed,
                                      late: _late),

                                if (_entries.isEmpty)
                                  const _EmptyHistory()
                                else ...[
                                  const SizedBox(height: 16),
                                  ..._entries.map(
                                      (e) => _HistoryItem(entry: e)),
                                ],
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                  ),
                  BottomNavigation(
                      active: 'history',
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

// ── Summary card ──────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int taken, missed, late;
  const _SummaryCard(
      {required this.taken, required this.missed, required this.late});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today_outlined,
                color: AppTheme.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo do dia',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(
                  '$taken tomado${taken != 1 ? 's' : ''}'
                  '${missed > 0 ? ' • $missed não tomado${missed != 1 ? 's' : ''}' : ''}'
                  '${late > 0 ? ' • $late atrasado${late != 1 ? 's' : ''}' : ''}',
                  style: const TextStyle(
                      color: Color(0xFF4B5563), fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            taken > 0 && missed == 0 && late == 0
                ? Icons.check_circle
                : Icons.info_outline,
            color: taken > 0 && missed == 0 && late == 0
                ? AppTheme.green
                : AppTheme.blue,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history_outlined,
                size: 64, color: AppTheme.textLight.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text('Nenhum registro para este dia',
                style: TextStyle(
                    color: AppTheme.textGray, fontSize: 14)),
            const SizedBox(height: 4),
            const Text(
                'Os registros aparecem conforme você marca os medicamentos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppTheme.textLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ── History item ──────────────────────────────────────────────
class _HistoryItem extends StatelessWidget {
  final HistoryEntry entry;
  const _HistoryItem({required this.entry});

  Map<String, dynamic> get _cfg {
    if (entry.isTaken) {
      return {
        'icon': Icons.check,
        'iconBg': AppTheme.green,
        'label': 'Tomado',
        'badgeBg': const Color(0xFFD1FAE5),
        'badgeText': AppTheme.green,
      };
    } else if (entry.isMissed) {
      return {
        'icon': Icons.close,
        'iconBg': AppTheme.red,
        'label': 'Não tomado',
        'badgeBg': const Color(0xFFFEE2E2),
        'badgeText': const Color(0xFFDC2626),
      };
    } else {
      return {
        'icon': Icons.access_time,
        'iconBg': AppTheme.amber,
        'label': 'Atrasado',
        'badgeBg': const Color(0xFFFEF3C7),
        'badgeText': const Color(0xFFD97706),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: cfg['iconBg'] as Color,
                  shape: BoxShape.circle),
              child: Icon(cfg['icon'] as IconData,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.horario,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textGray)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cfg['badgeBg'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(cfg['label'] as String,
                            style: TextStyle(
                                color: cfg['badgeText'] as Color,
                                fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(entry.nome ?? 'Medicamento',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text(entry.dosagem ?? '',
                      style: const TextStyle(
                          color: AppTheme.textGray, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
