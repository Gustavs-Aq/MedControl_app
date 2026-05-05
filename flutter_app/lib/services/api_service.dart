// ============================================================
//  ApiService  –  cliente HTTP para o servidor Dart
//  Baseado em: medcontrol_full/flutter/lib/services/api_service.dart
//  Todas as rotas do servidor expandido
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Troque para o IP da máquina ao testar em dispositivo físico
  static const String _base = 'http://localhost:8080';

  static final _headers = {'Content-Type': 'application/json'};

  // ── AUTH ──────────────────────────────────────────────────

  static Future<AppUser?> register({
    required String nome,
    required String email,
    required String senha,
    required String dataNascimento,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'senha': senha,
          'data_nascimento': dataNascimento,
        }),
      );
      if (res.statusCode == 201) {
        return AppUser.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<AppUser?> login(String email, String senha) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'senha': senha}),
      );
      if (res.statusCode == 200) {
        return AppUser.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── MEDICATIONS ───────────────────────────────────────────

  static Future<List<Medication>> getMedications(int userId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/medications?user_id=$userId'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Medication.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Medication?> addMedication({
    required int userId,
    required String nome,
    required String dosagem,
    required int intervaloHoras,
    required int diasTratamento,
    required String dataInicio,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/medications'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'nome': nome,
          'dosagem': dosagem,
          'intervalo_horas': intervaloHoras,
          'dias_tratamento': diasTratamento,
          'data_inicio': dataInicio,
        }),
      );
      if (res.statusCode == 201) {
        return Medication.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteMedication(int id) async {
    try {
      final res =
          await http.delete(Uri.parse('$_base/medications/$id'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── SCHEDULES ─────────────────────────────────────────────

  static Future<List<Schedule>> getSchedules(int medicationId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/medications/$medicationId/schedules'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Schedule.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Schedule?> addSchedule(
      int medicationId, String horario) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/medications/$medicationId/schedules'),
        headers: _headers,
        body: jsonEncode({'horario': horario}),
      );
      if (res.statusCode == 201) {
        return Schedule.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  // ── HISTORY ───────────────────────────────────────────────

  static Future<List<HistoryEntry>> getHistory(
      int userId, String date) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/history?user_id=$userId&date=$date'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => HistoryEntry.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> markHistory({
    required int medicationId,
    required String data,
    required String horario,
    required String status,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/history'),
        headers: _headers,
        body: jsonEncode({
          'medication_id': medicationId,
          'data': data,
          'horario': horario,
          'status': status,
        }),
      );
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── REPORTS ───────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getAdherence(int userId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/reports/adherence?user_id=$userId'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── CAREGIVERS ────────────────────────────────────────────

  static Future<List<Caregiver>> getCaregivers(int userId) async {
    try {
      final res = await http.get(
          Uri.parse('$_base/caregivers?user_id=$userId'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => Caregiver.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Caregiver?> addCaregiver({
    required int userId,
    required String nome,
    String? telefone,
    String? email,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/caregivers'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'nome': nome,
          'telefone': telefone,
          'email': email,
        }),
      );
      if (res.statusCode == 201) {
        return Caregiver.fromJson(jsonDecode(res.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> deleteCaregiver(int id) async {
    try {
      final res =
          await http.delete(Uri.parse('$_base/caregivers/$id'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
