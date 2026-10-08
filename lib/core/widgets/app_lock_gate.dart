import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/security/app_lock_service.dart';
import '../../core/security/input_validation.dart';
import '../../l10n/strings.dart';

/// Gate shown at startup when the app lock is enabled (Phase 6).
///
/// Wraps the real home widget: while locked, only the PIN pad is
/// visible. Biometric unlock is offered when the device supports it
/// and the user enabled it in Settings.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _checked = false;
  bool _locked = false;
  bool _biometricAvailable = false;
  String _pin = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final enabled = await AppLockService.instance.isEnabled;
    final bio = enabled &&
        await AppLockService.instance.canUseBiometrics;
    if (!mounted) return;
    setState(() {
      _checked = true;
      _locked = enabled;
      _biometricAvailable = bio;
    });
    if (enabled && bio) {
      final bioOn = await _bioEnabled();
      if (bioOn && mounted) _tryBiometric();
    }
  }

  Future<bool> _bioEnabled() async {
    // ignore: avoid_redundant_argument_values
    try {
      return await AppLockService.instance.canUseBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await AppLockService.instance.authenticateBiometric();
    if (ok && mounted) setState(() => _locked = false);
  }

  void _onDigit(String d) {
    if (_pin.length >= 8) return;
    HapticFeedback.lightImpact();
    setState(() {
      _pin += d;
      _error = null;
    });
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (InputValidation.validatePin(_pin) != null) {
      setState(() => _error = S.of(context, 'applock_wrong'));
      return;
    }
    final ok = await AppLockService.instance.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _locked = false;
        _pin = '';
      });
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _error = S.of(context, 'applock_wrong');
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_locked) return widget.child;

    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Icon(Icons.lock_outline,
                  size: 56, color: colors.primary),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  S.of(context, 'applock_title'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              // PIN dots
              Semantics(
                label: S.of(context, 'applock_pin_semantics'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    8,
                    (i) => Container(
                      margin: const EdgeInsets.all(4),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: TextStyle(color: colors.error)),
              ],
              const SizedBox(height: 16),
              if (_biometricAvailable)
                TextButton.icon(
                  onPressed: _tryBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(S.of(context, 'applock_biometric')),
                ),
              const Spacer(),
              _pinPad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinPad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'back'],
    ];
    return Column(
      children: [
        for (final row in rows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final k in row) _pinKey(k)],
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _pin.isEmpty ? null : _submit,
          child: Text(S.of(context, 'applock_unlock')),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _pinKey(String k) {
    if (k.isEmpty) return const SizedBox(width: 72, height: 72);
    if (k == 'back') {
      return SizedBox(
        width: 72,
        height: 72,
        child: IconButton(
          onPressed: _onBackspace,
          icon: const Icon(Icons.backspace_outlined),
          tooltip: S.of(context, 'common_delete'),
        ),
      );
    }
    return SizedBox(
      width: 72,
      height: 72,
      child: Semantics(
        button: true,
        label: 'Digit $k',
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: () => _onDigit(k),
          child: Center(
            child: Text(k,
                style:
                    Theme.of(context).textTheme.headlineMedium),
          ),
        ),
      ),
    );
  }
}
