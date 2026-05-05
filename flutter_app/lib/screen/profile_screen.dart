import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';
import '../providers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ProfilePage extends StatefulWidget {
  final Function(String) onNavigate;
  const ProfilePage({super.key, required this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Caregiver> _caregivers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthController.instance.userId;
    final rows =
        await DatabaseHelper.instance.getCaregiversByUser(uid);
    setState(() {
      _caregivers = rows.map(Caregiver.fromJson).toList();
      _loading = false;
    });
  }

  Future<void> _deleteCaregiver(Caregiver c) async {
    await DatabaseHelper.instance.deleteCaregiver(c.id);
    showSnack(context, '${c.nome} removido');
    _load();
  }

  Future<void> _addCaregiver() async {
    final nomeCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar cuidador'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nome', hintText: 'Nome completo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: telCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration:
                  const InputDecoration(labelText: 'E-mail (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) return;
              await DatabaseHelper.instance.insertCaregiver({
                'user_id': AuthController.instance.userId,
                'nome': nomeCtrl.text.trim(),
                'telefone': telCtrl.text.trim().isEmpty
                    ? null
                    : telCtrl.text.trim(),
                'email': emailCtrl.text.trim().isEmpty
                    ? null
                    : emailCtrl.text.trim(),
              });
              Navigator.pop(context);
              _load();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja realmente sair?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.red),
            onPressed: () {
              Navigator.pop(context);
              AuthController.instance.logout();
              widget.onNavigate('login');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.instance;
    final user = auth.currentUser;

    return Container(
      color: AppTheme.green,
      child: Column(
        children: [
          const StatusBarWidget(dark: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Meu Perfil',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Gerencie suas informações',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
                Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // ── User card ─────────────────────
                          _UserCard(
                            user: user,
                            onEdit: () => _editProfile(user),
                          ),

                          const SizedBox(height: 20),

                          // ── Menu items ────────────────────
                          _MenuItem(
                            icon: Icons.people_outline,
                            label: 'Meus cuidadores',
                            trailing: Text(
                              '${_caregivers.length}',
                              style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 13),
                            ),
                            onTap: () => _showCaregivers(),
                          ),
                          const SizedBox(height: 8),
                          _MenuItem(
                            icon: Icons.alarm_outlined,
                            label: 'Configurações de lembrete',
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _MenuItem(
                            icon: Icons.notifications_outlined,
                            label: 'Notificações',
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _MenuItem(
                            icon: Icons.shield_outlined,
                            label: 'Segurança',
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _MenuItem(
                            icon: Icons.help_outline,
                            label: 'Ajuda e suporte',
                            onTap: () {},
                          ),
                          const SizedBox(height: 8),
                          _MenuItem(
                            icon: Icons.info_outline,
                            label: 'Sobre o MedControl',
                            onTap: () => _showAbout(),
                          ),

                          const SizedBox(height: 20),

                          // ── Logout button ─────────────────
                          GestureDetector(
                            onTap: _confirmLogout,
                            child: Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                  color: AppTheme.red,
                                  borderRadius:
                                      BorderRadius.circular(20)),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Sair da conta',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  BottomNavigation(
                      active: 'profile',
                      onNavigate: widget.onNavigate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Edit profile dialog ──────────────────────────────────
  Future<void> _editProfile(AppUser? user) async {
    if (user == null) return;
    final nomeCtrl = TextEditingController(text: user.nome);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar perfil'),
        content: TextField(
          controller: nomeCtrl,
          decoration: const InputDecoration(labelText: 'Nome completo'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) return;
              await DatabaseHelper.instance.updateUser(
                  user.id, {'nome': nomeCtrl.text.trim()});
              await AuthController.instance.refreshUser();
              Navigator.pop(context);
              setState(() {});
              showSnack(context, 'Perfil atualizado!');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.green),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // ── Caregivers bottom sheet ───────────────────────────────
  void _showCaregivers() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: const BoxDecoration(
                color: AppTheme.green,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cuidadores',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _addCaregiver();
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius:
                                  BorderRadius.circular(16)),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius:
                                  BorderRadius.circular(16)),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _caregivers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.people_outline,
                              size: 48,
                              color: AppTheme.textLight),
                          SizedBox(height: 8),
                          Text('Nenhum cuidador cadastrado',
                              style: TextStyle(
                                  color: AppTheme.textGray)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _caregivers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final c = _caregivers[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: AppTheme.bg,
                              borderRadius:
                                  BorderRadius.circular(16)),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: AppTheme.green
                                        .withOpacity(0.15),
                                    shape: BoxShape.circle),
                                child: const Icon(
                                    Icons.person,
                                    color: AppTheme.green,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(c.nome,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.textDark)),
                                    if (c.telefone != null)
                                      Text(c.telefone!,
                                          style: const TextStyle(
                                              color: AppTheme.textGray,
                                              fontSize: 12)),
                                    if (c.email != null)
                                      Text(c.email!,
                                          style: const TextStyle(
                                              color: AppTheme.textGray,
                                              fontSize: 12)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  _deleteCaregiver(c);
                                },
                                child: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.red,
                                    size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.medication, color: AppTheme.blue, size: 22),
            SizedBox(width: 8),
            Text('MedControl'),
          ],
        ),
        content: const Text(
          'MedControl v1.0.0\n\n'
          'Seu assistente de controle de medicamentos.\n\n'
          'Nunca mais esqueça de tomar seus remédios.\n\n'
          '© 2025 MedControl',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar')),
        ],
      ),
    );
  }
}

// ── User card ────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final AppUser? user;
  final VoidCallback onEdit;

  const _UserCard({required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF2DD4BF)]),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user != null ? user!.nome[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nome ?? 'Usuário',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                          color: AppTheme.textGray, fontSize: 12),
                    ),
                    if (user?.dataNascimento != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.cake_outlined,
                              size: 13, color: AppTheme.textLight),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(user!.dataNascimento),
                            style: const TextStyle(
                                color: AppTheme.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_outlined,
                      color: AppTheme.green, size: 16),
                  SizedBox(width: 6),
                  Text('Editar perfil',
                      style: TextStyle(
                          color: AppTheme.green, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    // YYYY-MM-DD → DD/MM/YYYY
    final parts = iso.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return iso;
  }
}

// ── Menu item ────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textGray, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textDark)),
            ),
            if (trailing != null) ...[
              trailing!,
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right,
                color: AppTheme.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
