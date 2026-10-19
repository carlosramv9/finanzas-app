import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/common.dart';
import '../providers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Sesión guardada + biometría activada: pedir huella/Face ID de inmediato.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locked =
          ref.read(authControllerProvider).value?.status == AuthStatus.locked;
      if (locked && mounted) _biometria();
    });
  }

  @override
  void dispose() {
    _correo.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _google() =>
      _guard(() => ref.read(authControllerProvider.notifier).signInWithGoogle());

  void _email() {
    if (!(_form.currentState?.validate() ?? false)) return;
    _guard(
      () => ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(_correo.text, _clave.text),
    );
  }

  void _biometria() => _guard(() async {
        final ok =
            await ref.read(authControllerProvider.notifier).unlockWithBiometrics();
        if (!ok && mounted) showInfo(context, 'No se pudo verificar tu identidad.');
      });

  Future<void> _olvide() async {
    final correo = _correo.text.trim();
    if (!correo.contains('@')) {
      showInfo(context, 'Escribe tu correo para enviarte el enlace.');
      return;
    }
    await _guard(() async {
      await ref.read(authControllerProvider.notifier).requestPasswordReset(correo);
      if (mounted) showInfo(context, 'Te enviamos un enlace a $correo.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked =
        ref.watch(authControllerProvider).value?.status == AuthStatus.locked;
    final faltantes = Env.faltantes;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (faltantes.isNotEmpty) ...[
                              _ConfigWarning(faltantes),
                              const SizedBox(height: 16),
                            ],
                            OutlinedButton.icon(
                              onPressed: _busy ? null : _google,
                              icon: const Icon(Icons.g_mobiledata, size: 28),
                              label: const Text('Continuar con Google'),
                            ),
                            const SizedBox(height: 20),
                            const _Divider(),
                            const SizedBox(height: 20),
                            _Field(
                              label: 'Correo',
                              child: TextFormField(
                                controller: _correo,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration:
                                    const InputDecoration(hintText: 'tu@correo.com'),
                                validator: (v) => (v ?? '').contains('@')
                                    ? null
                                    : 'Escribe un correo válido',
                              ),
                            ),
                            const SizedBox(height: 16),
                            _Field(
                              label: 'Contraseña',
                              child: TextFormField(
                                controller: _clave,
                                obscureText: true,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _email(),
                                decoration:
                                    const InputDecoration(hintText: '••••••••'),
                                validator: (v) => (v ?? '').isEmpty
                                    ? 'Escribe tu contraseña'
                                    : null,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _busy ? null : _olvide,
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _busy ? null : _email,
                              child: _busy
                                  ? const SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                            if (locked) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _busy ? null : _biometria,
                                icon: const Icon(Icons.lock_outline, size: 20),
                                label: const Text('Entrar con huella o Face ID'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.paddingOf(context).top + 48,
          24,
          40,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppLogo(),
            SizedBox(height: 20),
            Text(
              'Finanzas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tus cargos y abonos, en un solo lugar.',
              style: TextStyle(
                color: AppColors.onPrimaryMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'o con tu correo',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(child: Divider(color: AppColors.divider)),
        ],
      );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          child,
        ],
      );
}

class _ConfigWarning extends StatelessWidget {
  const _ConfigWarning(this.faltantes);

  final List<String> faltantes;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          border: Border.all(color: AppColors.warningBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Falta configurar: ${faltantes.join(', ')}.\n'
          'Ejecuta con --dart-define-from-file=env.json',
          style: const TextStyle(color: AppColors.warningText, fontSize: 13),
        ),
      );
}
