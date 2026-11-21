import 'package:material_ui/material_ui.dart';

import '../data/auth_repository.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.repository});

  final AuthRepository repository;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _switchMode() {
    _formKey.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    setState(() {
      _register = !_register;
      _error = null;
      _message = null;
    });
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      if (_register) {
        final signedIn = await widget.repository.signUp(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
        if (!signedIn && mounted) {
          _switchMode();
          setState(
            () => _message = 'Periksa email untuk konfirmasi akun, lalu masuk.',
          );
        }
      } else {
        await widget.repository.signIn(_email.text.trim(), _password.text);
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = _register ? 'Daftar' : 'Masuk';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'SiFinance',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _register ? 'Buat akun' : 'Masuk ke akun Anda',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      if (_register) ...[
                        TextFormField(
                          key: const ValueKey('name'),
                          controller: _name,
                          enabled: !_busy,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama lengkap',
                          ),
                          validator: (value) => value!.trim().isEmpty
                              ? 'Masukkan nama lengkap.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        key: const ValueKey('email'),
                        controller: _email,
                        enabled: !_busy,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value!.trim())
                            ? null
                            : 'Masukkan alamat email yang valid.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: const ValueKey('password'),
                        controller: _password,
                        enabled: !_busy,
                        obscureText: true,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        textInputAction: _register
                            ? TextInputAction.next
                            : TextInputAction.done,
                        onFieldSubmitted: _register ? null : (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Kata sandi',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Masukkan kata sandi.';
                          if (_register && value.length < 6) {
                            return 'Gunakan minimal 6 karakter.';
                          }
                          return null;
                        },
                      ),
                      if (_register) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('confirm-password'),
                          controller: _confirmation,
                          enabled: !_busy,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Konfirmasi kata sandi',
                          ),
                          validator: (value) => value == _password.text
                              ? null
                              : 'Kata sandi tidak cocok.',
                        ),
                      ],
                      if (_error != null || _message != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error ?? _message!,
                            style: _error == null
                                ? null
                                : TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Memproses…' : action),
                      ),
                      TextButton(
                        onPressed: _busy ? null : _switchMode,
                        child: Text(
                          _register
                              ? 'Sudah punya akun? Masuk'
                              : 'Belum punya akun? Daftar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
