import 'package:flutter/material.dart';

import '../core/app_routes.dart';
import '../core/formatters.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/mascot.dart';

/// Tela 3: Login / Cadastro.
///
/// Primeiro acesso: telefone + senha. Nos acessos seguintes a pessoa pode
/// usar a biometria (simulada). O formulário valida os campos e mostra
/// mensagens de erro claras, tanto abaixo de cada campo quanto em um aviso.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // GlobalKey<FormState> dá acesso ao estado do Form, para chamar
  // `validate()` quando a pessoa toca no botão.
  final _formKey = GlobalKey<FormState>();

  // Cada controller lê e controla o texto de um campo.
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegister = false; // false = entrar, true = criar conta
  bool _hidePassword = true;
  bool _loading = false;
  bool _showErrorsWhileTyping = false; // liga depois da primeira tentativa
  String? _error; // mensagem de erro vinda do "servidor"

  // Libera a memória dos controllers quando a tela é fechada.
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setMode(bool register) {
    setState(() {
      _isRegister = register;
      _error = null;
      _showErrorsWhileTyping = false;
    });
    _formKey.currentState?.reset();
  }

  // Preenche os campos com a conta de exemplo (útil na demonstração).
  void _fillDemoAccount() {
    setState(() {
      _isRegister = false;
      _error = null;
      _phoneController.text = AuthService.demoPhone;
      _passwordController.text = AuthService.demoPassword;
    });
  }

  // Valida o formulário e tenta entrar. É `async` porque simulamos uma
  // pequena espera, como se o app estivesse falando com um servidor.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus(); // fecha o teclado
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      setState(() => _showErrorsWhileTyping = true);
      showAppSnackBar(context, 'Confira os campos em vermelho.', isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return; // a tela pode ter sido fechada durante a espera

    final auth = AuthService.instance;
    final error = _isRegister
        ? auth.register(
            name: _nameController.text.trim(),
            phone: _phoneController.text,
            password: _passwordController.text,
          )
        : auth.login(_phoneController.text, _passwordController.text);

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      showAppSnackBar(context, error, isError: true);
      return;
    }

    _goToApp();
  }

  // Simula a biometria com uma janela de confirmação (AlertDialog).
  Future<void> _useBiometrics() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: const Text('Biometria (simulada)', style: AppText.h2),
        content: const Text(
          'Em um aparelho de verdade, aqui você encostaria o dedo no sensor '
          'ou olharia para a câmera.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (AuthService.instance.loginWithBiometrics()) {
      _goToApp();
    } else {
      showAppSnackBar(
        context,
        'Entre com telefone e senha uma vez para ativar a biometria.',
        isError: true,
      );
    }
  }

  // Abre a área da família e remove as telas anteriores da pilha, para o
  // botão "voltar" não levar de volta ao login.
  void _goToApp() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canUseBiometrics = AuthService.instance.canUseBiometrics;
    final error = _error;

    return Scaffold(
      appBar: buildAppBar(
        title: _isRegister ? 'Criar conta' : 'Entrar',
        audioText: _isRegister
            ? 'Criar conta. Digite seu nome, o número do celular e uma senha com pelo menos 6 caracteres.'
            : 'Entrar. Digite o número do celular e a senha. Se já entrou antes, você pode usar a digital.',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                const Mascot(height: 84),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isRegister
                        ? 'Vamos criar a sua conta?'
                        : 'Que bom ver você de novo!',
                    style: AppText.h1.copyWith(fontSize: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Entrar',
                    selected: !_isRegister,
                    onTap: () => _setMode(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    label: 'Criar conta',
                    selected: _isRegister,
                    onTap: () => _setMode(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              autovalidateMode: _showErrorsWhileTyping
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: AppText.body.copyWith(fontSize: 18),
                      decoration: appInputDecoration(
                        label: 'Como podemos te chamar?',
                        icon: Icons.person,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Digite o seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [PhoneInputFormatter()],
                    style: AppText.body.copyWith(fontSize: 18),
                    decoration: appInputDecoration(
                      label: 'Celular com DDD',
                      hint: '(11) 98888-1234',
                      icon: Icons.phone_android,
                    ),
                    validator: (value) {
                      if (phoneDigits(value ?? '').length != 11) {
                        return 'Digite o DDD e o número: 11 números.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction:
                        _isRegister ? TextInputAction.next : TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!_isRegister) _submit();
                    },
                    style: AppText.body.copyWith(fontSize: 18),
                    decoration: appInputDecoration(
                      label: 'Senha',
                      icon: Icons.lock,
                      suffix: IconButton(
                        tooltip: _hidePassword ? 'Mostrar senha' : 'Esconder senha',
                        icon: Icon(
                          _hidePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: (value) {
                      final text = value ?? '';
                      if (text.isEmpty) {
                        return _isRegister ? 'Crie uma senha.' : 'Digite a sua senha.';
                      }
                      if (text.length < 6) {
                        return 'A senha precisa ter pelo menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  if (_isRegister) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      style: AppText.body.copyWith(fontSize: 18),
                      decoration: appInputDecoration(
                        label: 'Repita a senha',
                        icon: Icons.lock_outline,
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'As senhas não são iguais.';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: error),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: _isRegister ? 'Criar minha conta' : 'Entrar na minha conta',
              loading: _loading,
              onPressed: _submit,
            ),
            if (!_isRegister)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _fillDemoAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.petrol,
                    minimumSize: const Size(48, 48),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Usar a conta de exemplo'),
                ),
              ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: AppText.small),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Entrar com digital ou rosto',
              icon: Icons.fingerprint,
              kind: AppButtonKind.light,
              showArrow: false,
              onPressed: canUseBiometrics ? _useBiometrics : null,
            ),
            if (!canUseBiometrics)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'A biometria fica disponível depois do primeiro acesso.',
                  textAlign: TextAlign.center,
                  style: AppText.small,
                ),
              ),
            const SizedBox(height: 20),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield, color: AppColors.petrol, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Seus dados ficam protegidos. Pedimos só o necessário e '
                    'você decide o que compartilhar (LGPD).',
                    style: AppText.small,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão do seletor "Entrar" / "Criar conta".
class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.petrol : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppColors.petrol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de erro com ícone, texto e cor (nunca só a cor).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brickSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brick, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.brickDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.brickDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
