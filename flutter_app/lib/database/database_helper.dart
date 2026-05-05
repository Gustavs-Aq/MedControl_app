// ============================================================
//  DatabaseHelper  –  SQLite local (sqflite)
//  Tabelas: users, medications, schedules, history, caregivers
//  Schema: darthave/sqlite.sql
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'medcontrol.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int _) async {
    // ── users ──────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        nome            TEXT    NOT NULL,
        email           TEXT    NOT NULL UNIQUE,
        senha           TEXT    NOT NULL,
        data_nascimento TEXT    NOT NULL,
        created_at      TEXT    DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ── medications ────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medications (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id          INTEGER NOT NULL,
        nome             TEXT    NOT NULL,
        dosagem          TEXT    NOT NULL,
        intervalo_horas  INTEGER NOT NULL,
        dias_tratamento  INTEGER NOT NULL,
        data_inicio      TEXT    NOT NULL,
        ativo            INTEGER DEFAULT 1,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // ── schedules ──────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedules (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        horario       TEXT    NOT NULL,
        FOREIGN KEY (medication_id)
          REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // ── history ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        data          TEXT    NOT NULL,
        horario       TEXT    NOT NULL,
        status        TEXT    NOT NULL,
        FOREIGN KEY (medication_id)
          REFERENCES medications(id) ON DELETE CASCADE
      )
    ''');

    // ── caregivers ─────────────────────────────────────────
    await db.execute('''
      CREATE TABLE IF NOT EXISTS caregivers (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id  INTEGER NOT NULL,
        nome     TEXT    NOT NULL,
        telefone TEXT,
        email    TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
  }

  // ══════════════════════════════════════════════════════════
  //  USERS
  // ══════════════════════════════════════════════════════════

  Future<int> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('users', data,
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final r = await db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()]);
    return r.isNotEmpty ? r.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final r =
        await db.query('users', where: 'id = ?', whereArgs: [id]);
    return r.isNotEmpty ? r.first : null;
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════
  //  MEDICATIONS
  // ══════════════════════════════════════════════════════════

  Future<int> insertMedication(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('medications', data);
  }

  Future<List<Map<String, dynamic>>> getMedicationsByUser(int userId) async {
    final db = await database;
    return db.query('medications',
        where: 'user_id = ? AND ativo = 1',
        whereArgs: [userId],
        orderBy: 'id DESC');
  }

  Future<Map<String, dynamic>?> getMedicationById(int id) async {
    final db = await database;
    final r = await db
        .query('medications', where: 'id = ?', whereArgs: [id]);
    return r.isNotEmpty ? r.first : null;
  }

  Future<void> updateMedication(int id, Map<String, dynamic> data) async {
    final db = await database;
    await db.update('medications', data,
        where: 'id = ?', whereArgs: [id]);
  }

  /// Soft-delete: marca ativo = 0
  Future<void> deleteMedication(int id) async {
    final db = await database;
    await db.update('medications', {'ativo': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // ══════════════════════════════════════════════════════════
  //  SCHEDULES
  // ══════════════════════════════════════════════════════════

  Future<int> insertSchedule(int medicationId, String horario) async {
    final db = await database;
    return db.insert('schedules',
        {'medication_id': medicationId, 'horario': horario});
  }

  Future<List<Map<String, dynamic>>> getSchedulesByMedication(
      int medId) async {
    final db = await database;
    return db.query('schedules',
        where: 'medication_id = ?',
        whereArgs: [medId],
        orderBy: 'horario ASC');
  }

  Future<void> deleteSchedulesByMedication(int medId) async {
    final db = await database;
    await db.delete('schedules',
        where: 'medication_id = ?', whereArgs: [medId]);
  }

  /// JOIN schedules + medications para o dia corrente
  Future<List<Map<String, dynamic>>> getTodaySchedules(
      int userId, String today) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        s.id        AS schedule_id,
        s.horario,
        m.id        AS medication_id,
        m.nome,
        m.dosagem,
        m.intervalo_horas,
        (SELECT status FROM history
         WHERE medication_id = m.id
           AND data    = ?
           AND horario = s.horario
         LIMIT 1) AS status
      FROM schedules s
      JOIN medications m ON m.id = s.medication_id
      WHERE m.user_id = ? AND m.ativo = 1
      ORDER BY s.horario ASC
    ''', [today, userId]);
  }

  // ══════════════════════════════════════════════════════════
  //  HISTORY
  // ══════════════════════════════════════════════════════════

  /// Upsert: se já existe entrada para med+data+horário, atualiza status
  Future<void> upsertHistory(Map<String, dynamic> data) async {
    final db = await database;
    final existing = await db.query(
      'history',
      where: 'medication_id = ? AND data = ? AND horario = ?',
      whereArgs: [data['medication_id'], data['data'], data['horario']],
    );
    if (existing.isEmpty) {
      await db.insert('history', data);
    } else {
      await db.update(
        'history',
        {'status': data['status']},
        where: 'medication_id = ? AND data = ? AND horario = ?',
        whereArgs: [data['medication_id'], data['data'], data['horario']],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getHistoryByDate(
      int userId, String date) async {
    final db = await database;
    return db.rawQuery('''
      SELECT h.*, m.nome, m.dosagem
      FROM history h
      JOIN medications m ON m.id = h.medication_id
      WHERE m.user_id = ? AND h.data = ?
      ORDER BY h.horario ASC
    ''', [userId, date]);
  }

  Future<List<Map<String, dynamic>>> getRecentHistory(
      int userId, int days) async {
    final db = await database;
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String()
        .substring(0, 10);
    return db.rawQuery('''
      SELECT h.*, m.nome, m.dosagem
      FROM history h
      JOIN medications m ON m.id = h.medication_id
      WHERE m.user_id = ? AND h.data >= ?
      ORDER BY h.data DESC, h.horario DESC
    ''', [userId, since]);
  }

  /// Retorna taxa de adesão dos últimos 7 dias por dia
  Future<List<Map<String, dynamic>>> getWeeklyAdherence(int userId) async {
    final db = await database;
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      final rows = await db.rawQuery('''
        SELECT
          COUNT(*) AS total,
          SUM(CASE WHEN status = 'tomado' THEN 1 ELSE 0 END) AS taken
        FROM history h
        JOIN medications m ON m.id = h.medication_id
        WHERE m.user_id = ? AND h.data = ?
      ''', [userId, dateStr]);

      final total = (rows.first['total'] as int?) ?? 0;
      final taken = (rows.first['taken'] as int?) ?? 0;
      results.add({
        'date': dateStr,
        'label': _weekdayLabel(day.weekday),
        'total': total,
        'taken': taken,
        'rate': total > 0 ? taken / total : 0.0,
      });
    }
    return results;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return labels[(weekday - 1) % 7];
  }

  // ══════════════════════════════════════════════════════════
  //  CAREGIVERS
  // ══════════════════════════════════════════════════════════

  Future<int> insertCaregiver(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('caregivers', data);
  }

  Future<List<Map<String, dynamic>>> getCaregiversByUser(
      int userId) async {
    final db = await database;
    return db.query('caregivers',
        where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> deleteCaregiver(int id) async {
    final db = await database;
    await db.delete('caregivers', where: 'id = ?', whereArgs: [id]);
  }
}
