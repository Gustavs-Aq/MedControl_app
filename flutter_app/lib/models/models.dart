// ============================================================
//  Models  –  baseado em medcontrol_full/flutter/lib/models/
// ============================================================

// ── Medication ───────────────────────────────────────────────
class Medication {
  final int id;
  final int userId;
  final String nome;
  final String dosagem;
  final int intervaloHoras;
  final int diasTratamento;
  final String dataInicio;
  final bool ativo;

  const Medication({
    required this.id,
    required this.userId,
    required this.nome,
    required this.dosagem,
    required this.intervaloHoras,
    required this.diasTratamento,
    required this.dataInicio,
    this.ativo = true,
  });

  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        nome: j['nome'] as String,
        dosagem: j['dosagem'] as String,
        intervaloHoras: j['intervalo_horas'] as int,
        diasTratamento: j['dias_tratamento'] as int,
        dataInicio: j['data_inicio'] as String,
        ativo: (j['ativo'] ?? 1) == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'nome': nome,
        'dosagem': dosagem,
        'intervalo_horas': intervaloHoras,
        'dias_tratamento': diasTratamento,
        'data_inicio': dataInicio,
        'ativo': ativo ? 1 : 0,
      };

  // Color index for UI variety
  int get colorIndex => id % 5;
}

// ── User ─────────────────────────────────────────────────────
class AppUser {
  final int id;
  final String nome;
  final String email;
  final String dataNascimento;
  final String createdAt;

  const AppUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.dataNascimento,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        nome: j['nome'] as String,
        email: j['email'] as String,
        dataNascimento: j['data_nascimento'] as String,
        createdAt: j['created_at'] as String? ?? '',
      );

  String get firstName => nome.split(' ').first;
}

// ── Schedule ─────────────────────────────────────────────────
class Schedule {
  final int id;
  final int medicationId;
  final String horario;

  const Schedule({
    required this.id,
    required this.medicationId,
    required this.horario,
  });

  factory Schedule.fromJson(Map<String, dynamic> j) => Schedule(
        id: j['id'] as int,
        medicationId: j['medication_id'] as int,
        horario: j['horario'] as String,
      );
}

// ── HistoryEntry ─────────────────────────────────────────────
class HistoryEntry {
  final int id;
  final int medicationId;
  final String data;
  final String horario;
  final String status; // 'tomado' | 'nao_tomado' | 'atrasado'
  final String? nome;
  final String? dosagem;

  const HistoryEntry({
    required this.id,
    required this.medicationId,
    required this.data,
    required this.horario,
    required this.status,
    this.nome,
    this.dosagem,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: j['id'] as int,
        medicationId: j['medication_id'] as int,
        data: j['data'] as String,
        horario: j['horario'] as String,
        status: j['status'] as String,
        nome: j['nome'] as String?,
        dosagem: j['dosagem'] as String?,
      );

  bool get isTaken => status == 'tomado';
  bool get isMissed => status == 'nao_tomado';
  bool get isLate => status == 'atrasado';
}

// ── TodaySchedule (JOIN schedules + medications + history) ───
class TodaySchedule {
  final int scheduleId;
  final int medicationId;
  final String nome;
  final String dosagem;
  final String horario;
  final String? status;

  const TodaySchedule({
    required this.scheduleId,
    required this.medicationId,
    required this.nome,
    required this.dosagem,
    required this.horario,
    this.status,
  });

  factory TodaySchedule.fromJson(Map<String, dynamic> j) => TodaySchedule(
        scheduleId: j['schedule_id'] as int,
        medicationId: j['medication_id'] as int,
        nome: j['nome'] as String,
        dosagem: j['dosagem'] as String,
        horario: j['horario'] as String,
        status: j['status'] as String?,
      );

  bool get isTaken => status == 'tomado';
  bool get isPending => status == null;
  bool get isLate => status == 'atrasado';

  String get displayStatus {
    if (isTaken) return 'taken';
    if (isLate) return 'delayed';
    // Check if time has passed
    final now = DateTime.now();
    final parts = horario.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final schedTime = DateTime(now.year, now.month, now.day, h, m);
      if (schedTime.isBefore(now)) return 'upcoming';
    }
    return 'pending';
  }
}

// ── Caregiver ─────────────────────────────────────────────────
class Caregiver {
  final int id;
  final int userId;
  final String nome;
  final String? telefone;
  final String? email;

  const Caregiver({
    required this.id,
    required this.userId,
    required this.nome,
    this.telefone,
    this.email,
  });

  factory Caregiver.fromJson(Map<String, dynamic> j) => Caregiver(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        nome: j['nome'] as String,
        telefone: j['telefone'] as String?,
        email: j['email'] as String?,
      );
}
