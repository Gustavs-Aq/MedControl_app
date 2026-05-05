// ============================================================
//  AuthController  –  baseado em darthave/auth_controller.dart
//  Gerencia sessão + operações de auth com SQLite local
// ============================================================

import '../database/database_helper.dart';
import '../models/models.dart';

class AuthController {
  static final AuthController instance = AuthController._();
  AuthController._();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLogged => _currentUser != null;
  int get userId => _currentUser?.id ?? 0;
  String get userName => _currentUser?.nome ?? 'Usuário';
  String get userFirstName => _currentUser?.firstName ?? 'Usuário';
  String get userEmail => _currentUser?.email ?? '';

  // ── Login ─────────────────────────────────────────────────

  Future<String?> login(String email, String senha) async {
    if (email.trim().isEmpty || senha.isEmpty) {
      return 'Preencha e-mail e senha';
    }

    final row = await DatabaseHelper.instance
        .getUserByEmail(email.trim().toLowerCase());

    if (row == null) return 'E-mail não encontrado';
    if (row['senha'] != senha) return 'Senha incorreta';

    _currentUser = AppUser.fromJson(row);
    return null; // sucesso
  }

  // ── Registro ──────────────────────────────────────────────

  Future<String?> register({
    required String nome,
    required String email,
    required String senha,
    required String confirmarSenha,
    required String dataNascimento,
  }) async {
    if (nome.trim().isEmpty ||
        email.trim().isEmpty ||
        senha.isEmpty ||
        dataNascimento.isEmpty) {
      return 'Preencha todos os campos obrigatórios';
    }

    if (senha != confirmarSenha) return 'As senhas não conferem';
    if (senha.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }

    final existing = await DatabaseHelper.instance
        .getUserByEmail(email.trim().toLowerCase());
    if (existing != null) return 'E-mail já cadastrado';

    try {
      final id = await DatabaseHelper.instance.insertUser({
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'senha': senha,
        'data_nascimento': dataNascimento,
      });

      final row = await DatabaseHelper.instance.getUserById(id);
      _currentUser = AppUser.fromJson(row!);
      return null;
    } catch (_) {
      return 'Erro ao criar conta. Tente novamente.';
    }
  }

  // ── Logout ────────────────────────────────────────────────

  void logout() => _currentUser = null;

  // ── Refresh ───────────────────────────────────────────────

  Future<void> refreshUser() async {
    if (_currentUser == null) return;
    final row =
        await DatabaseHelper.instance.getUserById(_currentUser!.id);
    if (row != null) _currentUser = AppUser.fromJson(row);
  }
}
