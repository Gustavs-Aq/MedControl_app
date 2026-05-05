import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HomePage extends StatefulWidget {
  final Function(String) onNavigate;
  final VoidCallback onOpenAddMed;

  const HomePage(
      {super.key, required this.onNavigate, required this.onOpenAddMed});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<TodaySchedule> _schedules = [];
  double _adherence = 0.0;
  bool _loading = true;

  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthController.instance.userId;
    final rows = await DatabaseHelper.instance.getTodaySchedules(uid, _today);
    final week = await DatabaseHelper.instance.getWeeklyAdherence(uid);

    final totalWeek =
        week.fold<int>(0, (s, d) => s + (d['total'] as int));
    final takenWeek =
        week.fold<int>(0, (s, d) => s + (d['taken'] as int));

    setState(() {
      _schedules = rows.map(TodaySchedule.fromJson).toList();
      _adherence = totalWeek > 0 ? takenWeek / totalWeek : 0.0;
      _loading = false;
    });
  }

  Future<void> _markTaken(TodaySchedule s) async {
    await DatabaseHelper.instance.upsertHistory({
      'medication_id': s.medicationId,
      'data': _today,
      'horario': s.horario,
      'status': 'tomado',
    });
    _load();
  }

  // Próximo medicamento pendente
  TodaySchedule? get _next {
    final pending =
        _schedules.where((s) => !s.isTaken).toList();
    return pending.isNotEmpty ? pending.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance;

    return Container(
      color: AppTheme.bg,
      child: Column(
        children: [
          const StatusBarWidget(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          const PillIcon(size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Olá, ${user.userFirstName}!',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700)),
                                const Text('Seu tratamento, sempre em dia.',
                                    style: TextStyle(
                                        color: AppTheme.textGray,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_outlined,
                                  size: 26, color: AppTheme.textMid),
                              if (_next != null)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                        color: AppTheme.green,
                                        shape: BoxShape.circle),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Próxima medicação card ───────────────
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: AppTheme.green),
                      )
                    else if (_next != null) ...[
                      _NextMedCard(schedule: _next!, onMark: _markTaken),
                    ] else ...[
                      _AllDoneCard(),
                    ],

                    const SizedBox(height: 24),

                    // ── Medicamentos de hoje ─────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Medicamentos de hoje',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: () => widget.onNavigate('medications'),
                            child: const Row(children: [
                              Text('Ver todos',
                                  style: TextStyle(
                                      color: AppTheme.blue,
                                      fontSize: 13)),
                              Icon(Icons.chevron_right,
                                  color: AppTheme.blue, size: 18),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_schedules.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Nenhum medicamento para hoje. Adicione um!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textGray)),
                      )
                    else
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: _schedules
                              .map((s) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _MedCard(
                                        schedule: s, onMark: _markTaken),
                                  ))
                              .toList(),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── Aderência semanal ────────────────────
                    if (!_loading && _adherence > 0)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              AppTheme.green.withOpacity(0.12),
                              AppTheme.green.withOpacity(0.05),
                            ]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                    color: AppTheme.green,
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                child: const Icon(Icons.shield_outlined,
                                    color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _adherence >= 0.9
                                          ? 'Excelente!'
                                          : _adherence >= 0.7
                                              ? 'Bom progresso!'
                                              : 'Atenção!',
                                      style: const TextStyle(
                                          color: AppTheme.green,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      'Você está ${(_adherence * 100).round()}% aderente esta semana.',
                                      style: const TextStyle(
                                          color: Color(0xFF4B5563),
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      size: const Size(48, 48),
                                      painter: CircularProgressPainter(
                                        progress: _adherence,
                                        color: AppTheme.green,
                                        strokeWidth: 5,
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '${(_adherence * 100).round()}%',
                                        style: const TextStyle(
                                            color: AppTheme.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── Botão adicionar ──────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: GestureDetector(
                        onTap: widget.onOpenAddMed,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                              color: AppTheme.green,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text('Adicionar medicamento',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          BottomNavigation(active: 'home', onNavigate: widget.onNavigate),
        ],
      ),
    );
  }
}

// ── Próxima medicação card ────────────────────────────────────
class _NextMedCard extends StatelessWidget {
  final TodaySchedule schedule;
  final Function(TodaySchedule) onMark;

  const _NextMedCard({required this.schedule, required this.onMark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned(
              top: -24, right: -24,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.calendar_today,
                        color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Próxima medicação',
                        style: TextStyle(
                            color: Colors.white90, fontSize: 13)),
                  ]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(schedule.horario,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700)),
                          Text(schedule.nome,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                    color: AppTheme.green,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(schedule.dosagem,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                          ]),
                        ],
                      ),
                      Column(children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle),
                          child:
                              const Center(child: PillIcon(size: 50)),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => onMark(schedule),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: AppTheme.green,
                                borderRadius:
                                    BorderRadius.circular(20)),
                            child: const Row(children: [
                              Icon(Icons.check,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('Tomei',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13)),
                            ]),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Todos tomados ─────────────────────────────────────────────
class _AllDoneCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            AppTheme.green.withOpacity(0.15),
            AppTheme.green.withOpacity(0.05),
          ]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.green, size: 44),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tudo em dia! 🎉',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.green)),
                  SizedBox(height: 4),
                  Text(
                      'Você tomou todos os medicamentos de hoje.',
                      style: TextStyle(
                          color: Color(0xFF4B5563), fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card de medicamento do dia ────────────────────────────────
class _MedCard extends StatelessWidget {
  final TodaySchedule schedule;
  final Function(TodaySchedule) onMark;

  const _MedCard({required this.schedule, required this.onMark});

  Color get _color =>
      AppTheme.medColors[schedule.medicationId % AppTheme.medColors.length];

  @override
  Widget build(BuildContext context) {
    final bgColor = Color.fromRGBO(
        _color.red, _color.green, _color.blue, 0.06);

    return GestureDetector(
      onLongPress: schedule.isTaken ? null : () => onMark(schedule),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: schedule.isTaken
                      ? AppTheme.green
                      : schedule.displayStatus == 'upcoming'
                          ? AppTheme.blue
                          : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: Icon(Icons.access_time, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schedule.horario,
                      style: TextStyle(
                          color: _color,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  Text(schedule.nome,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text(schedule.dosagem,
                      style: const TextStyle(
                          color: AppTheme.textGray, fontSize: 12)),
                ],
              ),
            ),
            _badge(),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _badge() {
    if (schedule.isTaken) {
      return _pill('Tomado', AppTheme.green,
          icon: Icons.check);
    } else if (schedule.displayStatus == 'upcoming') {
      return _pill('Próximo', AppTheme.blue);
    } else {
      return _pill('Pendente', AppTheme.textLight,
          textColor: AppTheme.textGray,
          bg: const Color(0xFFE5E7EB));
    }
  }

  Widget _pill(String label, Color color,
      {IconData? icon,
      Color? textColor,
      Color? bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: bg ?? color,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? Colors.white, size: 13),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: textColor ?? Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
