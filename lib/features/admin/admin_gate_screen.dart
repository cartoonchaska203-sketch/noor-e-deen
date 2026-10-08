import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/security/input_validation.dart';
import '../../l10n/strings.dart';
import 'admin_screen.dart';
import 'admin_service.dart';

/// PIN gate for the Admin CMS (Phase 6).
///
/// First launch: set a 4–8 digit PIN (stored in the platform keychain).
/// Later launches: verify the PIN. 5 wrong attempts lock the screen
/// for 60 seconds (simple brute-force deterrent).
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  bool _loading = true;
  bool _hasPin = false;
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  int _attempts = 0;
  DateTime? _lockedUntil;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final has = await AdminService.instance.hasPin;
    if (mounted) {
      setState(() {
        _hasPin = has;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  bool get _isLockedOut =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_isLockedOut) {
      setState(() => _error = S.of(context, 'admin_locked_out'));
      return;
    }
    if (!_hasPin) {
      // Setup mode: both entries must match.
      final e1 = InputValidation.validatePin(_pin1.text.trim());
      if (e1 != null) {
        setState(() => _error = InputValidation.message(e1));
        return;
      }
      if (_pin1.text.trim() != _pin2.text.trim()) {
        setState(() => _error = S.of(context, 'admin_pin_mismatch'));
        return;
      }
      await AdminService.instance.setPin(_pin1.text.trim());
      if (mounted) _enter();
      return;
    }
    // Verify mode.
    final ok =
        await AdminService.instance.verifyPin(_pin1.text.trim());
    if (!mounted) return;
    if (ok) {
      _enter();
    } else {
      HapticFeedback.vibrate();
      _attempts++;
      if (_attempts >= 5) {
        _lockedUntil = DateTime.now().add(const Duration(seconds: 60));
        _attempts = 0;
      }
      setState(() => _error = S.of(context, 'admin_pin_wrong'));
    }
  }

  void _enter() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'admin_title'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                _hasPin
                    ? S.of(context, 'admin_enter_pin')
                    : S.of(context, 'admin_set_pin'),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context, 'admin_pin_note'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pin1,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                labelText: S.of(context, 'admin_pin'),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (!_hasPin) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pin2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: S.of(context, 'admin_pin_confirm'),
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLockedOut ? null : _submit,
              child: Text(S.of(context,
                  _hasPin ? 'admin_unlock' : 'admin_set_pin_button')),
            ),
          ],
        ),
      ),
    );
  }
}
