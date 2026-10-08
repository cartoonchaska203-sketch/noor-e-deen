import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/services/location_service.dart';
import '../../core/services/qibla_service.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common_widgets.dart';
import '../../l10n/strings.dart';
import '../settings/settings_screen.dart';

/// Qibla direction screen.
///
/// Bearing + distance are computed with pure math from the GPS/manual
/// position — always correct, no sensors needed. A live magnetometer
/// compass dial is a Phase 2 enhancement; until then the dial shows the
/// bearing from true North with step-by-step guidance.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  late Future<ResolvedLocation> _locationFuture;

  @override
  void initState() {
    super.initState();
    _locationFuture = _resolve();
  }

  Future<ResolvedLocation> _resolve() {
    final state = AppState.instance;
    return LocationService.resolve(
      mode: state.locationMode,
      manualCityName: state.manualCity,
    );
  }

  void _refresh() {
    setState(() {
      _locationFuture = _resolve();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context, 'qibla_title'))),
      body: FutureBuilder<ResolvedLocation>(
        future: _locationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingView(label: S.of(context, 'common_loading'));
          }
          final loc = snapshot.data;
          if (snapshot.hasError || loc == null) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: _refresh,
            );
          }
          QiblaResult? result;
          try {
            result = QiblaService.calculate(loc.lat, loc.lon);
          } catch (_) {
            result = null;
          }
          if (result == null) {
            return ErrorView(
              message: S.of(context, 'common_error'),
              retryLabel: S.of(context, 'common_retry'),
              onRetry: _refresh,
            );
          }
          return _buildBody(context, loc, result);
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, ResolvedLocation loc, QiblaResult result) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (loc.usedFallback)
          InfoCard(
            icon: Icons.info_outline,
            title: loc.label,
            body: S.of(context, 'prayer_gps_issue'),
            trailing: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Text(S.of(context, 'prayer_open_settings')),
            ),
          )
        else
          InfoCard(
            icon: Icons.location_on_outlined,
            title: S.of(context, 'prayer_location'),
            body: loc.label,
            trailing: IconButton(
              tooltip: S.of(context, 'prayer_refresh'),
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: _QiblaDialPainter(
                bearing: result.bearing,
                primary: Theme.of(context).colorScheme.primary,
                secondary: Theme.of(context).colorScheme.secondary,
                ink: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.explore_outlined,
                label: S.of(context, 'qibla_bearing'),
                value: '${result.bearing.toStringAsFixed(1)}°',
                sub: S.of(context, 'qibla_from_north'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.straighten_outlined,
                label: S.of(context, 'qibla_distance'),
                value: _formatDistance(result.distanceKm),
                sub: 'Makkah',
              ),
            ),
          ],
        ),
        SectionTitle(S.of(context, 'qibla_how')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Step(number: 1, text: S.of(context, 'qibla_step1')),
                _Step(number: 2, text: S.of(context, 'qibla_step2')),
                _Step(number: 3, text: S.of(context, 'qibla_step3')),
                _Step(number: 4, text: S.of(context, 'qibla_step4')),
                const SizedBox(height: 8),
                Text(
                  S.of(context, 'qibla_calibrate'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDistance(double km) {
    final String digits = km.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$digits km';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(sub, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Static compass dial: North at top, gold needle at the Qibla bearing.
class _QiblaDialPainter extends CustomPainter {
  _QiblaDialPainter({
    required this.bearing,
    required this.primary,
    required this.secondary,
    required this.ink,
  });

  final double bearing;
  final Color primary;
  final Color secondary;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2 - 8;

    final Paint ring = Paint()
      ..color = primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius - 14, ring);

    // Tick marks every 15°.
    final Paint tick = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (int deg = 0; deg < 360; deg += 15) {
      final double a = deg * pi / 180;
      final bool major = deg % 90 == 0;
      final Offset p1 = center +
          Offset(cos(a), sin(a)) * (radius - (major ? 16 : 10));
      final Offset p2 =
          center + Offset(cos(a), sin(a)) * (radius - 4);
      canvas.drawLine(p1, p2, tick);
    }

    // Cardinal labels (N at top = -90° in canvas coords).
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, double deg, Color c, double fontSize) {
      tp.text = TextSpan(
        text: s,
        style: TextStyle(
            color: c, fontSize: fontSize, fontWeight: FontWeight.w800),
      );
      tp.layout();
      final double a = (deg - 90) * pi / 180;
      final Offset p = center +
          Offset(cos(a), sin(a)) * (radius - 32) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, p);
    }

    label('N', 0, primary, 18);
    label('E', 90, ink.withValues(alpha: 0.7), 14);
    label('S', 180, ink.withValues(alpha: 0.7), 14);
    label('W', 270, ink.withValues(alpha: 0.7), 14);

    // Qibla needle at bearing (clockwise from North).
    final double a = (bearing - 90) * pi / 180;
    final Offset tip = center + Offset(cos(a), sin(a)) * (radius - 20);
    final Offset tail = center - Offset(cos(a), sin(a)) * 26;
    final Offset left = center +
        Offset(cos(a + pi / 2), sin(a + pi / 2)) * 10 -
        Offset(cos(a), sin(a)) * 10;
    final Offset right = center +
        Offset(cos(a - pi / 2), sin(a - pi / 2)) * 10 -
        Offset(cos(a), sin(a)) * 10;

    final Paint needle = Paint()
      ..color = secondary
      ..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(), needle);

    final Paint tailPaint = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(tail, 7, tailPaint);
    canvas.drawCircle(center, 5, Paint()..color = primary);
  }

  @override
  bool shouldRepaint(covariant _QiblaDialPainter oldDelegate) {
    return oldDelegate.bearing != bearing;
  }
}
