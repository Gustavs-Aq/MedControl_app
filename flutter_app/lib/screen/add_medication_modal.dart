import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../providers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class AddMedicationModal extends StatefulWidget {
  final VoidCallback onClose;
  const AddMedicationModal({super.key, required this.onClose});

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '30');

  String _unit = 'comprimido';
  String _frequency = '';
  List<TimeOfDay?> _times = [null];
  bool _saving = false;

  static const _freqOptions = {
    '1x': '1 vez ao dia (24h)',
    '2x': '2 vezes ao dia (12h)',
    '3x': '3 vezes ao dia (8h)',
    '4x': '4 vezes ao dia (6h)',
  };

  static const _unitOptions = {
    'comprimido': 'Comprimido',
    'cápsula': 'Cápsula',
    'gota': 'Gota(s)',
    'ml': 'ML',
    'spray': 'Spray',
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  // ── Salvar no SQLite ─────────────────────────────────────
  Future<void> _save() async {
    final nome = _nameCtrl.text.trim();
    final dosagem = _dosageCtrl.text.trim();
    final days = int.tryParse(_daysCtrl.text) ?? 30;

    if (nome.isEmpty || dosagem.isEmpty) {
      showSnack(context, 'Preencha nome e dosagem', error: true);
      return;
    }
    if (_times.every((t) => t == null)) {
      showSnack(context, 'Adicione pelo menos um horário', error: true);
      return;
    }

    setState(() => _saving = true);

    final intervalo = _freqToInterval(_frequency);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      // 1. Inserir medicamento
      final medId = await DatabaseHelper.instance.insertMedication({
        'user_id': AuthController.instance.userId,
        'nome': nome,
        'dosagem': '$dosagem $_unit',
        'intervalo_horas': intervalo,
        'dias_tratamento': days,
        'data_inicio': today,
        'ativo': 1,
      });

      // 2. Inserir horários
      for (final t in _times) {
        if (t != null) {
          final horario =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          await DatabaseHelper.instance.insertSchedule(medId, horario);
        }
      }

      showSnack(context, '✅ Medicamento adicionado com sucesso!');
      widget.onClose();
    } catch (e) {
      showSnack(context, 'Erro ao salvar: $e', error: true);
      setState(() => _saving = false);
    }
  }

  int _freqToInterval(String freq) {
    switch (freq) {
      case '2x':
        return 12;
      case '3x':
        return 8;
      case '4x':
        return 6;
      default:
        return 24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: _slide,
            child: Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.92),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  Flexible(child: _form()),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────
  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppTheme.blue, AppTheme.blueDark]),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adicionar Medicamento',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Preencha as informações do medicamento',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      );

  // ── Form ─────────────────────────────────────────────────
  Widget _form() => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nome do medicamento'),
            _input(_nameCtrl, 'Ex: Paracetamol',
                icon: Icons.medication_outlined),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label('Dosagem'),
                      _input(_dosageCtrl, 'Ex: 750mg',
                          keyboardType: TextInputType.number),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _label('Tipo'),
                      _dropdown(
                        value: _unit,
                        items: _unitOptions,
                        onChanged: (v) => setState(() => _unit = v!),
                      ),
                    ])),
              ],
            ),
            const SizedBox(height: 14),
            _label('Dias de tratamento'),
            _input(_daysCtrl, '30',
                keyboardType: TextInputType.number,
                icon: Icons.calendar_today_outlined),
            const SizedBox(height: 14),
            _label('Frequência'),
            _dropdown(
              value: _frequency.isEmpty ? null : _frequency,
              items: _freqOptions,
              hint: 'Selecione a frequência',
              onChanged: (v) => setState(() => _frequency = v ?? ''),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _label('Horários'),
                GestureDetector(
                  onTap: () => setState(() => _times.add(null)),
                  child: Row(
                    children: const [
                      Icon(Icons.add,
                          color: AppTheme.green, size: 16),
                      SizedBox(width: 4),
                      Text('Adicionar horário',
                          style: TextStyle(
                              color: AppTheme.green, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._times.asMap().entries.map((e) => _timeField(e.key)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Os horários definidos serão usados para gerar lembretes e registrar o histórico de doses.',
                      style: TextStyle(
                          color: Color(0xFF1E3A8A), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── Footer ───────────────────────────────────────────────
  Widget _footer() => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.borderLight))),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('Cancelar',
                      style: TextStyle(
                          color: AppTheme.textMid, fontSize: 15)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color:
                          _saving ? Colors.grey : AppTheme.green,
                      borderRadius: BorderRadius.circular(12)),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Adicionar',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      );

  // ── Helpers ──────────────────────────────────────────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.textMid, fontSize: 13)));

  Widget _input(TextEditingController c, String hint,
      {IconData? icon, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppTheme.textLight, fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: AppTheme.textLight, size: 18)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.blue, width: 2)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: AppTheme.bg,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String? value,
    required Map<String, String> items,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: hint != null
              ? Text(hint,
                  style: const TextStyle(
                      color: AppTheme.textLight, fontSize: 14))
              : null,
          items: items.entries
              .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value,
                      style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _timeField(int index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final t = await showTimePicker(
                      context: context,
                      initialTime:
                          _times[index] ?? TimeOfDay.now());
                  if (t != null) setState(() => _times[index] = t);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                      color: AppTheme.bg,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: AppTheme.textLight, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _times[index] != null
                            ? _times[index]!.format(context)
                            : 'Selecionar horário',
                        style: TextStyle(
                            color: _times[index] != null
                                ? AppTheme.textDark
                                : AppTheme.textLight,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_times.length > 1) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () =>
                    setState(() => _times.removeAt(index)),
                child: Container(
                  width: 40,
                  height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.close,
                      color: AppTheme.red, size: 18),
                ),
              ),
            ],
          ],
        ),
      );
}
