import 'package:flutter/material.dart';
import '../providers/auth_controller.dart';
import '../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const RegisterScreen({super.key, required this.onNavigate});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();
  bool _showPw = false, _showConfirm = false;
  bool _loading = false;
  String? _dia, _mes, _ano;
  bool _termos = false;

  final _dias = List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));
  final _meses = List.generate(12, (i) => (i + 1).toString().padLeft(2, '0'));
  final _anos = List.generate(80,
      (i) => (DateTime.now().year - 18 - i).toString());

  Future<void> _register() async {
    if (!_termos) {
      showSnack(context, 'Aceite os Termos de Uso', error: true);
      return;
    }
    if (_dia == null || _mes == null || _ano == null) {
      showSnack(context, 'Informe a data de nascimento', error: true);
      return;
    }
    setState(() => _loading = true);
    final error = await AuthController.instance.register(
      nome: _nomeCtrl.text,
      email: _emailCtrl.text,
      senha: _senhaCtrl.text,
      confirmarSenha: _confirmaCtrl.text,
      dataNascimento: '$_ano-$_mes-$_dia',
    );
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
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2563EB),
      child: Column(
        children: [
          const StatusBarWidget(dark: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => widget.onNavigate('login'),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Criar conta',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                      'Preencha os dados abaixo para criar sua conta',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 24),
                  _wfield(_nomeCtrl, 'Nome completo',
                      icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  _wfield(_emailCtrl, 'E-mail',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _wfield(_senhaCtrl, 'Senha',
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
                  const SizedBox(height: 12),
                  _wfield(_confirmaCtrl, 'Confirmar senha',
                      icon: Icons.lock_outline,
                      obscure: !_showConfirm,
                      suffix: GestureDetector(
                        onTap: () => setState(
                            () => _showConfirm = !_showConfirm),
                        child: Icon(
                            _showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9CA3AF),
                            size: 20),
                      )),
                  const SizedBox(height: 20),
                  const Text('Data de nascimento',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _drop('DD', _dias, _dia,
                              (v) => setState(() => _dia = v))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _drop('MM', _meses, _mes,
                              (v) => setState(() => _mes = v))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _drop('AAAA', _anos, _ano,
                              (v) => setState(() => _ano = v))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _termos,
                          onChanged: (v) =>
                              setState(() => _termos = v ?? false),
                          activeColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                            'Eu li e aceito os Termos de Uso e Política de Privacidade',
                            style: TextStyle(
                                color: Colors.white90, fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _loading ? null : _register,
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
                          : const Text('Criar conta',
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
                      const Text('Já tem uma conta? ',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      GestureDetector(
                        onTap: () => widget.onNavigate('login'),
                        child: const Text('Entrar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                decoration:
                                    TextDecoration.underline,
                                decorationColor: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wfield(TextEditingController c, String hint,
      {IconData? icon,
      bool obscure = false,
      Widget? suffix,
      TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
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

  Widget _drop(String hint, List<String> items, String? value,
      ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF9CA3AF))),
          items: items
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
