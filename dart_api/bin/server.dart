// ============================================================
//  MedControl API  –  Servidor REST em Dart puro
//  Porta padrão: 8080
//  Base: medcontrol_full/dart_backend/server.dart  (ampliado)
// ============================================================

import 'dart:convert';
import 'dart:io';

// ── Banco em memória (substitua por sqlite3 em produção) ─────
// Em produção use o pacote sqlite3 e o schema do sqlite.sql
final _db = _InMemoryDb();

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('🚀 MedControl API rodando em http://localhost:8080');

  await for (final req in server) {
    _addCorsHeaders(req.response);

    // Preflight OPTIONS
    if (req.method == 'OPTIONS') {
      req.response.statusCode = 200;
      await req.response.close();
      continue;
    }

    try {
      await _route(req);
    } catch (e) {
      _send(req.response, 500, {'error': e.toString()});
    }
  }
}

// ── Roteador ─────────────────────────────────────────────────
Future<void> _route(HttpRequest req) async {
  final path = req.uri.path;
  final method = req.method;
  final body = await _readBody(req);

  // ── AUTH ──────────────────────────────────────────────────
  if (method == 'POST' && path == '/auth/register') {
    final user = _db.createUser(body);
    return _send(req.response, 201, user);
  }

  if (method == 'POST' && path == '/auth/login') {
    final user = _db.login(body['email'] ?? '', body['senha'] ?? '');
    if (user == null) return _send(req.response, 401, {'error': 'Credenciais inválidas'});
    return _send(req.response, 200, user);
  }

  // ── USERS ─────────────────────────────────────────────────
  final userMatch = RegExp(r'^/users/(\d+)$').firstMatch(path);
  if (method == 'GET' && userMatch != null) {
    final id = int.parse(userMatch.group(1)!);
    final user = _db.getUser(id);
    if (user == null) return _send(req.response, 404, {'error': 'Usuário não encontrado'});
    return _send(req.response, 200, user);
  }

  if (method == 'PUT' && userMatch != null) {
    final id = int.parse(userMatch.group(1)!);
    final user = _db.updateUser(id, body);
    if (user == null) return _send(req.response, 404, {'error': 'Usuário não encontrado'});
    return _send(req.response, 200, user);
  }

  // ── MEDICATIONS ───────────────────────────────────────────
  if (method == 'GET' && path == '/medications') {
    final userId = int.tryParse(req.uri.queryParameters['user_id'] ?? '');
    return _send(req.response, 200, _db.getMedications(userId));
  }

  if (method == 'POST' && path == '/medications') {
    final med = _db.createMedication(body);
    return _send(req.response, 201, med);
  }

  final medMatch = RegExp(r'^/medications/(\d+)$').firstMatch(path);
  if (medMatch != null) {
    final id = int.parse(medMatch.group(1)!);
    if (method == 'GET') {
      final med = _db.getMedication(id);
      if (med == null) return _send(req.response, 404, {'error': 'Medicamento não encontrado'});
      return _send(req.response, 200, med);
    }
    if (method == 'PUT') {
      final med = _db.updateMedication(id, body);
      if (med == null) return _send(req.response, 404, {'error': 'Medicamento não encontrado'});
      return _send(req.response, 200, med);
    }
    if (method == 'DELETE') {
      _db.deleteMedication(id);
      return _send(req.response, 200, {'status': 'ok'});
    }
  }

  // ── SCHEDULES ─────────────────────────────────────────────
  final schedMatch = RegExp(r'^/medications/(\d+)/schedules$').firstMatch(path);
  if (schedMatch != null) {
    final medId = int.parse(schedMatch.group(1)!);
    if (method == 'GET') {
      return _send(req.response, 200, _db.getSchedules(medId));
    }
    if (method == 'POST') {
      final s = _db.createSchedule(medId, body);
      return _send(req.response, 201, s);
    }
  }

  // ── HISTORY ───────────────────────────────────────────────
  if (method == 'GET' && path == '/history') {
    final userId = int.tryParse(req.uri.queryParameters['user_id'] ?? '');
    final date = req.uri.queryParameters['date'];
    return _send(req.response, 200, _db.getHistory(userId, date));
  }

  if (method == 'POST' && path == '/history') {
    final entry = _db.createHistory(body);
    return _send(req.response, 201, entry);
  }

  // ── REPORTS ───────────────────────────────────────────────
  if (method == 'GET' && path == '/reports/adherence') {
    final userId = int.tryParse(req.uri.queryParameters['user_id'] ?? '') ?? 0;
    return _send(req.response, 200, _db.getAdherence(userId));
  }

  // ── CAREGIVERS ────────────────────────────────────────────
  if (method == 'GET' && path == '/caregivers') {
    final userId = int.tryParse(req.uri.queryParameters['user_id'] ?? '');
    return _send(req.response, 200, _db.getCaregivers(userId));
  }

  if (method == 'POST' && path == '/caregivers') {
    final c = _db.createCaregiver(body);
    return _send(req.response, 201, c);
  }

  final cgMatch = RegExp(r'^/caregivers/(\d+)$').firstMatch(path);
  if (cgMatch != null && method == 'DELETE') {
    _db.deleteCaregiver(int.parse(cgMatch.group(1)!));
    return _send(req.response, 200, {'status': 'ok'});
  }

  // 404
  _send(req.response, 404, {'error': 'Rota não encontrada: $method $path'});
}

// ── Helpers ──────────────────────────────────────────────────
void _addCorsHeaders(HttpResponse res) {
  res.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    ..contentType = ContentType.json;
}

Future<Map<String, dynamic>> _readBody(HttpRequest req) async {
  try {
    final raw = await utf8.decoder.bind(req).join();
    if (raw.isEmpty) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  } catch (_) {
    return {};
  }
}

void _send(HttpResponse res, int status, dynamic data) {
  res.statusCode = status;
  res.write(jsonEncode(data));
  res.close();
}

// ══════════════════════════════════════════════════════════════
//  Banco em memória  (mesmas tabelas do sqlite.sql)
// ══════════════════════════════════════════════════════════════
class _InMemoryDb {
  // ── users ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _users = [];
  int _userId = 1;

  Map<String, dynamic> createUser(Map<String, dynamic> data) {
    final user = {
      'id': _userId++,
      'nome': data['nome'] ?? '',
      'email': (data['email'] ?? '').toString().toLowerCase(),
      'senha': data['senha'] ?? '',
      'data_nascimento': data['data_nascimento'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
    _users.add(user);
    return _safeUser(user);
  }

  Map<String, dynamic>? login(String email, String senha) {
    final u = _users.where((u) =>
        u['email'] == email.toLowerCase() && u['senha'] == senha).firstOrNull;
    return u != null ? _safeUser(u) : null;
  }

  Map<String, dynamic>? getUser(int id) {
    final u = _users.where((u) => u['id'] == id).firstOrNull;
    return u != null ? _safeUser(u) : null;
  }

  Map<String, dynamic>? updateUser(int id, Map<String, dynamic> data) {
    final idx = _users.indexWhere((u) => u['id'] == id);
    if (idx == -1) return null;
    _users[idx] = {..._users[idx], ...data, 'id': id};
    return _safeUser(_users[idx]);
  }

  Map<String, dynamic> _safeUser(Map<String, dynamic> u) =>
      {...u}..remove('senha');

  // ── medications ────────────────────────────────────────────
  final List<Map<String, dynamic>> _meds = [];
  int _medId = 1;

  List<Map<String, dynamic>> getMedications(int? userId) => _meds
      .where((m) =>
          m['ativo'] == 1 && (userId == null || m['user_id'] == userId))
      .toList();

  Map<String, dynamic> createMedication(Map<String, dynamic> data) {
    final med = {
      'id': _medId++,
      'user_id': data['user_id'],
      'nome': data['nome'] ?? '',
      'dosagem': data['dosagem'] ?? '',
      'intervalo_horas': data['intervalo_horas'] ?? 8,
      'dias_tratamento': data['dias_tratamento'] ?? 30,
      'data_inicio': data['data_inicio'] ?? DateTime.now().toIso8601String().substring(0, 10),
      'ativo': 1,
    };
    _meds.add(med);
    return med;
  }

  Map<String, dynamic>? getMedication(int id) =>
      _meds.where((m) => m['id'] == id).firstOrNull;

  Map<String, dynamic>? updateMedication(int id, Map<String, dynamic> data) {
    final idx = _meds.indexWhere((m) => m['id'] == id);
    if (idx == -1) return null;
    _meds[idx] = {..._meds[idx], ...data, 'id': id};
    return _meds[idx];
  }

  void deleteMedication(int id) {
    final idx = _meds.indexWhere((m) => m['id'] == id);
    if (idx != -1) _meds[idx]['ativo'] = 0;
  }

  // ── schedules ──────────────────────────────────────────────
  final List<Map<String, dynamic>> _schedules = [];
  int _schedId = 1;

  List<Map<String, dynamic>> getSchedules(int medId) =>
      _schedules.where((s) => s['medication_id'] == medId).toList();

  Map<String, dynamic> createSchedule(int medId, Map<String, dynamic> data) {
    final s = {
      'id': _schedId++,
      'medication_id': medId,
      'horario': data['horario'] ?? '08:00',
    };
    _schedules.add(s);
    return s;
  }

  // ── history ────────────────────────────────────────────────
  final List<Map<String, dynamic>> _history = [];
  int _histId = 1;

  List<Map<String, dynamic>> getHistory(int? userId, String? date) {
    return _history.where((h) {
      if (date != null && h['data'] != date) return false;
      if (userId != null) {
        final med = getMedication(h['medication_id'] as int);
        if (med == null || med['user_id'] != userId) return false;
      }
      return true;
    }).toList();
  }

  Map<String, dynamic> createHistory(Map<String, dynamic> data) {
    // Upsert por medication_id + data + horario
    final idx = _history.indexWhere((h) =>
        h['medication_id'] == data['medication_id'] &&
        h['data'] == data['data'] &&
        h['horario'] == data['horario']);
    final entry = {
      'id': idx == -1 ? _histId++ : _history[idx]['id'],
      'medication_id': data['medication_id'],
      'data': data['data'],
      'horario': data['horario'],
      'status': data['status'] ?? 'tomado',
    };
    if (idx == -1) {
      _history.add(entry);
    } else {
      _history[idx] = entry;
    }
    return entry;
  }

  // ── reports ────────────────────────────────────────────────
  Map<String, dynamic> getAdherence(int userId) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final dayHistory = _history.where((h) {
        if (h['data'] != dateStr) return false;
        final med = getMedication(h['medication_id'] as int);
        return med != null && med['user_id'] == userId;
      }).toList();
      final total = dayHistory.length;
      final taken = dayHistory.where((h) => h['status'] == 'tomado').length;
      return {
        'date': dateStr,
        'total': total,
        'taken': taken,
        'rate': total > 0 ? (taken / total * 100).round() : 0,
      };
    });
    final totalWeek = days.fold<int>(0, (s, d) => s + (d['total'] as int));
    final takenWeek = days.fold<int>(0, (s, d) => s + (d['taken'] as int));
    return {
      'days': days,
      'weekly_rate': totalWeek > 0 ? (takenWeek / totalWeek * 100).round() : 0,
    };
  }

  // ── caregivers ─────────────────────────────────────────────
  final List<Map<String, dynamic>> _caregivers = [];
  int _cgId = 1;

  List<Map<String, dynamic>> getCaregivers(int? userId) => _caregivers
      .where((c) => userId == null || c['user_id'] == userId)
      .toList();

  Map<String, dynamic> createCaregiver(Map<String, dynamic> data) {
    final c = {
      'id': _cgId++,
      'user_id': data['user_id'],
      'nome': data['nome'] ?? '',
      'telefone': data['telefone'],
      'email': data['email'],
    };
    _caregivers.add(c);
    return c;
  }

  void deleteCaregiver(int id) => _caregivers.removeWhere((c) => c['id'] == id);
}
