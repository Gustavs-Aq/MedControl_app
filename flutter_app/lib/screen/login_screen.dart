import 'package:flutter/material.dart';
import '../providers/auth_controller.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const LoginScreen({super.key, required this.onNavigate});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _showPw = false;
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    final error = await AuthController.instance
        .login(_emailCtrl.text, _senhaCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      showSnack(context, error, error: true);
    } else {
      widget.onNavigate('home');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          const StatusBarWidget(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const PillIcon(size: 80),
                  const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(children: [
                      TextSpan(
                          text: 'Med',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB))),
                      TextSpan(
                          text: 'Control',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981))),
                    ]),
                  ),
                  const SizedBox(height: 4),
                  const Text('Seu tratamento, sempre em dia.',
                      style: TextStyle(
                          color: Color(0xFF6B7280), fontSize: 13)),
                  const SizedBox(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Bem-vindo de volta!',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Faça login para continuar',
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 13)),
                  ),
                  const SizedBox(height: 20),
                  _field(_emailCtrl, 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _field(_senhaCtrl, 'Senha',
                      icon: Icons.lock_outline,
                      obscure: !_showPw,
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _showPw = !_showPw),
                        child: Icon(
                            _showPw
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20),
                      )),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _loading ? null : _login,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                          color: _loading
                              ? Colors.grey
                              : const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Entrar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Não tem uma conta? ',
                          style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13)),
                      GestureDetector(
                        onTap: () =>
                            widget.onNavigate('register'),
                        child: const Text('Cadastre-se',
                            style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {IconData? icon,
      bool obscure = false,
      Widget? suffix,
      TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF), fontSize: 14),
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF9CA3AF), size: 20)
              : null,
          suffixIcon: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
