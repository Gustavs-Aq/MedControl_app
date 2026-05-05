import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MedicationsPage extends StatefulWidget {
  final Function(String) onNavigate;
  final VoidCallback onOpenAddMed;

  const MedicationsPage(
      {super.key, required this.onNavigate, required this.onOpenAddMed});

  @override
  State<MedicationsPage> createState() => _MedicationsPageState();
}

class _MedicationsPageState extends State<MedicationsPage> {
  List<Medication> _all = [];
  List<Medication> _filtered = [];
  Map<int, List<Schedule>> _scheduleMap = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthController.instance.userId;
    final rows = await DatabaseHelper.instance.getMedicationsByUser(uid);
    final meds = rows.map(Medication.fromJson).toList();

    final map = <int, List<Schedule>>{};
    for (final m in meds) {
      final srows = await DatabaseHelper.instance.getSchedulesByMedication(m.id);
      map[m.id] = srows.map(Schedule.fromJson).toList();
    }

    setState(() {
      _all = meds;
      _filtered = meds;
      _scheduleMap = map;
      _loading = false;
    });
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _filtered = _all
          .where((m) => m.nome.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Future<void> _delete(Medication med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover medicamento'),
        content: Text('Deseja remover "${med.nome}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover',
                  style: TextStyle(color: AppTheme.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteMedication(med.id);
      showSnack(context, '${med.nome} removido');
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.blue,
      child: Column(
        children: [
          const StatusBarWidget(dark: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meus Medicamentos',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Gerencie seus medicamentos',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        widget.onOpenAddMed();
                        await Future.delayed(
                            const Duration(milliseconds: 600));
                        _load();
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.add,
                            color: AppTheme.blue, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    onChanged: _search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar medicamentos',
                      hintStyle: TextStyle(
                          color: AppTheme.textLight, fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: AppTheme.textLight, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                            child: _filtered.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.medication_outlined,
                                            size: 60,
                                            color: AppTheme.textLight),
                                        const SizedBox(height: 12),
                                        Text(
                                          _query.isEmpty
                                              ? 'Nenhum medicamento cadastrado'
                                              : 'Nenhum resultado para "$_query"',
                                          style: const TextStyle(
                                              color: AppTheme.textGray),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 24, 24, 24),
                                    itemCount: _filtered.length + 1,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (ctx, i) {
                                      if (i == _filtered.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              top: 8),
                                          child: GestureDetector(
                                            onTap: widget.onOpenAddMed,
                                            child: Container(
                                              height: 56,
                                              decoration: BoxDecoration(
                                                  color: AppTheme.green,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20)),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add,
                                                      color: Colors.white,
                                                      size: 22),
                                                  SizedBox(width: 8),
                                                  Text(
                                                      'Adicionar medicamento',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      final med = _filtered[i];
                                      final schedules =
                                          _scheduleMap[med.id] ?? [];
                                      return _MedItem(
                                        med: med,
                                        schedules: schedules,
                                        onDelete: () => _delete(med),
                                      );
                                    },
                                  ),
                          ),
                  ),
                  BottomNavigation(
                      active: 'medications',
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

class _MedItem extends StatelessWidget {
  final Medication med;
  final List<Schedule> schedules;
  final VoidCallback onDelete;

  const _MedItem(
      {required this.med,
      required this.schedules,
      required this.onDelete});

  Color get _color => AppTheme.medColors[med.id % AppTheme.medColors.length];

  @override
  Widget build(BuildContext context) {
    final frequencyLabel = _freqLabel(med.intervaloHoras);

    return Dismissible(
      key: Key('med_${med.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: AppTheme.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: AppTheme.red, size: 26),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  shape: BoxShape.circle),
              child: Center(
                child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: _color, shape: BoxShape.circle)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.nome,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark)),
                  Text(med.dosagem,
                      style: const TextStyle(
                          color: AppTheme.textGray, fontSize: 12)),
                  Text(frequencyLabel,
                      style: const TextStyle(
                          color: AppTheme.textLight, fontSize: 11)),
                  if (schedules.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 13, color: AppTheme.textLight),
                        const SizedBox(width: 4),
                        ...schedules
                            .take(4)
                            .map((s) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(s.horario,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF4B5563))),
                                )),
                        if (schedules.length > 4)
                          Text('+${schedules.length - 4}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: med.ativo
                        ? AppTheme.green.withOpacity(0.12)
                        : AppTheme.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    med.ativo ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                        fontSize: 10,
                        color: med.ativo ? AppTheme.green : AppTheme.red,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right,
                    color: AppTheme.textLight, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _freqLabel(int horas) {
    switch (horas) {
      case 6:
        return '4 vezes ao dia (6h em 6h)';
      case 8:
        return '3 vezes ao dia (8h em 8h)';
      case 12:
        return '2 vezes ao dia (12h em 12h)';
      default:
        return '1 vez ao dia';
    }
  }
}
