import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Zakat calculator: 2.5% on zakatable assets above nisab.
/// Gold/silver rates: live fetch (gold-api.com + open.er-api.com) with
/// manual override and clearly-labeled fallbacks. Always shows the
/// scholar-consultation disclaimer.
class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatState {
  String currency = 'GBP';
  bool useSilverNisab = false;
  final cash = TextEditingController();
  final bank = TextEditingController();
  final goldG = TextEditingController();
  final silverG = TextEditingController();
  final investments = TextEditingController();
  final business = TextEditingController();
  final receivables = TextEditingController();
  final liabilities = TextEditingController();
  final goldRate = TextEditingController();
  final silverRate = TextEditingController();
  bool ratesLive = false;
  String? rateNote;
  bool loadingRates = false;

  void dispose() {
    for (final c in [
      cash, bank, goldG, silverG, investments,
      business, receivables, liabilities, goldRate, silverRate,
    ]) {
      c.dispose();
    }
  }
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _s = _ZakatState();
  final _repo = UserDataRepository.instance;
  _ZakatResult? _result;
  late Future<List<Map<String, dynamic>>> _historyFuture;

  static const _symbols = {'GBP': '£', 'USD': '\$', 'PKR': 'Rs'};

  // Fallback per-gram rates in USD (labeled as estimates).
  static const _fallbackGoldUsdG = 130.0;
  static const _fallbackSilverUsdG = 1.9;
  static const _fallbackFx = {'GBP': 0.79, 'USD': 1.0, 'PKR': 278.0};

  @override
  void initState() {
    super.initState();
    _historyFuture = _repo.zakatHistory();
    _initRates();
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  Future<void> _initRates() async {
    final overrides = await _repo.metalRateOverrides();
    final key = _s.currency;
    if (overrides.containsKey('gold_$key') &&
        overrides.containsKey('silver_$key')) {
      setState(() {
        _s.goldRate.text = overrides['gold_$key']!.toStringAsFixed(2);
        _s.silverRate.text = overrides['silver_$key']!.toStringAsFixed(2);
        _s.rateNote = S.of(context, 'zakat_rates_manual');
      });
      return;
    }
    // Sensible labeled defaults until the user refreshes.
    setState(() {
      _s.goldRate.text =
          (_fallbackGoldUsdG * _fallbackFx[key]!).toStringAsFixed(2);
      _s.silverRate.text =
          (_fallbackSilverUsdG * _fallbackFx[key]!).toStringAsFixed(2);
      _s.rateNote = S.of(context, 'zakat_rates_estimate');
    });
  }

  Future<void> _refreshRates() async {
    setState(() {
      _s.loadingRates = true;
      _s.rateNote = null;
    });
    try {
      final goldRes = await http
          .get(Uri.parse('https://api.gold-api.com/price/XAU'))
          .timeout(const Duration(seconds: 12));
      final silverRes = await http
          .get(Uri.parse('https://api.gold-api.com/price/XAG'))
          .timeout(const Duration(seconds: 12));
      final fxRes = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 12));
      if (goldRes.statusCode != 200 ||
          silverRes.statusCode != 200 ||
          fxRes.statusCode != 200) {
        throw Exception('rate fetch failed');
      }
      const troyOzG = 31.1035;
      final goldUsdOz =
          (jsonDecode(goldRes.body) as Map<String, dynamic>)['price'] as num;
      final silverUsdOz =
          (jsonDecode(silverRes.body) as Map<String, dynamic>)['price'] as num;
      final fx = (jsonDecode(fxRes.body)
          as Map<String, dynamic>)['rates'] as Map<String, dynamic>;
      final rate = (fx[_s.currency] as num?)?.toDouble() ??
          _fallbackFx[_s.currency]!;
      final goldG = goldUsdOz.toDouble() / troyOzG * rate;
      final silverG = silverUsdOz.toDouble() / troyOzG * rate;
      await _repo.setMetalRateOverrides(
          {'gold_${_s.currency}': goldG, 'silver_${_s.currency}': silverG});
      if (!mounted) return;
      setState(() {
        _s.goldRate.text = goldG.toStringAsFixed(2);
        _s.silverRate.text = silverG.toStringAsFixed(2);
        _s.ratesLive = true;
        _s.rateNote = S.of(context, 'zakat_rates_live');
        _s.loadingRates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _s.loadingRates = false;
        _s.rateNote = S.of(context, 'zakat_rates_failed');
      });
    }
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.trim()) ?? 0.0;

  void _calculate() {
    final sym = _symbols[_s.currency]!;
    final goldG = _num(_s.goldG);
    final silverG = _num(_s.silverG);
    final goldVal = goldG * _num(_s.goldRate);
    final silverVal = silverG * _num(_s.silverRate);
    final assets = _num(_s.cash) +
        _num(_s.bank) +
        goldVal +
        silverVal +
        _num(_s.investments) +
        _num(_s.business) +
        _num(_s.receivables);
    final net = assets - _num(_s.liabilities);
    final nisabG = _s.useSilverNisab ? 612.36 : 87.48;
    final nisabVal =
        nisabG * (_s.useSilverNisab ? _num(_s.silverRate) : _num(_s.goldRate));
    final due = net >= nisabVal && net > 0 ? net * 0.025 : 0.0;
    setState(() {
      _result = _ZakatResult(
        assets: assets,
        net: net,
        nisabGrams: nisabG,
        nisabValue: nisabVal,
        due: due,
        aboveNisab: net >= nisabVal,
        currency: _s.currency,
        symbol: sym,
        breakdown: {
          S.of(context, 'zakat_cash'): _num(_s.cash),
          S.of(context, 'zakat_bank'): _num(_s.bank),
          '${S.of(context, 'zakat_gold')} ($goldG g)': goldVal,
          '${S.of(context, 'zakat_silver')} ($silverG g)': silverVal,
          S.of(context, 'zakat_investments'): _num(_s.investments),
          S.of(context, 'zakat_business'): _num(_s.business),
          S.of(context, 'zakat_receivables'): _num(_s.receivables),
          S.of(context, 'zakat_liabilities'): -_num(_s.liabilities),
        },
      );
    });
  }

  Future<void> _saveResult() async {
    final r = _result;
    if (r == null) return;
    await _repo.recordZakat({
      'date': DateTime.now().toIso8601String(),
      'currency': r.currency,
      'net': r.net,
      'nisab': r.nisabValue,
      'due': r.due,
    });
    setState(() => _historyFuture = _repo.zakatHistory());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context, 'zakat_saved'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'zakat_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _disclaimer(),
          SectionTitle(S.of(context, 'zakat_currency_nisab')),
          Row(
            children: [
              Expanded(child: _currencyPicker()),
              const SizedBox(width: 12),
              Expanded(child: _nisabToggle()),
            ],
          ),
          SectionTitle(S.of(context, 'zakat_rates')),
          _ratesCard(),
          SectionTitle(S.of(context, 'zakat_assets')),
          _moneyField(_s.cash, 'zakat_cash', TextInputType.number),
          _moneyField(_s.bank, 'zakat_bank', TextInputType.number),
          _moneyField(_s.goldG, 'zakat_gold_g', TextInputType.number),
          _moneyField(_s.silverG, 'zakat_silver_g', TextInputType.number),
          _moneyField(
              _s.investments, 'zakat_investments', TextInputType.number),
          _moneyField(_s.business, 'zakat_business', TextInputType.number),
          _moneyField(
              _s.receivables, 'zakat_receivables', TextInputType.number),
          _moneyField(
              _s.liabilities, 'zakat_liabilities', TextInputType.number),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.calculate_outlined),
            label: Text(S.of(context, 'zakat_calculate')),
            onPressed: _calculate,
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            _resultCard(),
          ],
          SectionTitle(S.of(context, 'zakat_history')),
          _historyList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade700.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(S.of(context, 'zakat_disclaimer'),
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Widget _currencyPicker() {
    return DropdownButtonFormField<String>(
      initialValue: _s.currency,
      decoration: InputDecoration(
          labelText: S.of(context, 'zakat_currency'),
          border: const OutlineInputBorder()),
      items: [
        for (final c in ['GBP', 'USD', 'PKR'])
          DropdownMenuItem(value: c, child: Text(c)),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _s.currency = v;
          _s.ratesLive = false;
          _result = null;
        });
        _initRates();
      },
    );
  }

  Widget _nisabToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'zakat_nisab'),
            style: Theme.of(context).textTheme.labelLarge),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(
                value: false, label: Text(S.of(context, 'zakat_gold_nisab'))),
            ButtonSegment(
                value: true, label: Text(S.of(context, 'zakat_silver_nisab'))),
          ],
          selected: {_s.useSilverNisab},
          onSelectionChanged: (s) =>
              setState(() => _s.useSilverNisab = s.first),
        ),
        Text(
          _s.useSilverNisab
              ? S.of(context, 'zakat_silver_nisab_note')
              : S.of(context, 'zakat_gold_nisab_note'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _ratesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _s.goldRate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          '${S.of(context, 'zakat_gold_rate')} (${_symbols[_s.currency]}/g)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _s.silverRate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText:
                          '${S.of(context, 'zakat_silver_rate')} (${_symbols[_s.currency]}/g)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _s.rateNote == null
                      ? const SizedBox.shrink()
                      : Text(_s.rateNote!,
                          style: Theme.of(context).textTheme.bodySmall),
                ),
                TextButton.icon(
                  icon: _s.loadingRates
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(S.of(context, 'zakat_refresh_rates')),
                  onPressed: _s.loadingRates ? null : _refreshRates,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _moneyField(
      TextEditingController c, String labelKey, TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: type,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: S.of(context, labelKey),
          prefixText: '${_symbols[_s.currency]} ',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _resultCard() {
    final r = _result!;
    final colors = Theme.of(context).colorScheme;
    String fmt(double v) =>
        '${r.symbol}${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context, 'zakat_result'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final e in r.breakdown.entries)
              if (e.value != 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(e.key)),
                      Text(fmt(e.value),
                          style: TextStyle(
                              color: e.value < 0 ? colors.error : null)),
                    ],
                  ),
                ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context, 'zakat_net_assets'),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(fmt(r.net),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${S.of(context, 'zakat_nisab_value')} (${r.nisabGrams}g)'),
                Text(fmt(r.nisabValue)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    r.aboveNisab
                        ? S.of(context, 'zakat_due_label')
                        : S.of(context, 'zakat_not_due'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt(r.due),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary),
                  ),
                  Text(S.of(context, 'zakat_rate_note'),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.save_outlined),
                label: Text(S.of(context, 'zakat_save')),
                onPressed: _saveResult,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _historyFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final h = snap.data!;
        if (h.isEmpty) {
          return Text(S.of(context, 'zakat_history_empty'),
              style: Theme.of(context).textTheme.bodySmall);
        }
        return Column(
          children: [
            for (final e in h.take(10))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text(
                      '${_symbols[e['currency'] as String? ?? 'GBP']}${((e['due'] as num?) ?? 0).toStringAsFixed(2)}'),
                  subtitle: Text((e['date'] as String? ?? '').substring(0, 10)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ZakatResult {
  _ZakatResult({
    required this.assets,
    required this.net,
    required this.nisabGrams,
    required this.nisabValue,
    required this.due,
    required this.aboveNisab,
    required this.currency,
    required this.symbol,
    required this.breakdown,
  });

  final double assets;
  final double net;
  final double nisabGrams;
  final double nisabValue;
  final double due;
  final bool aboveNisab;
  final String currency;
  final String symbol;
  final Map<String, double> breakdown;
}
