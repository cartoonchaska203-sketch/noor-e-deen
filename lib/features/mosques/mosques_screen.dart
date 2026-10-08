import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/location_service.dart';
import '../../core/services/mosques/mosque_service.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/offline_banner.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../l10n/strings.dart';

/// Nearby mosques via the free OpenStreetMap Overpass API (no key needed).
///
/// Data quality depends on OSM contributors. An optional Google Places
/// upgrade is documented in mosque_service.dart (GOOGLE_PLACES_API_KEY).
class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});

  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Future<_MosqueLoad>? _loadFuture;
  Set<String> _favs = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loadFuture = _fetch();
    });
    _favs = await UserDataRepository.instance.mosqueFavorites();
    if (mounted) setState(() {});
  }

  Future<_MosqueLoad> _fetch() async {
    final state = AppState.instance;
    final loc = await LocationService.resolve(
      mode: state.locationMode,
      manualCityName: state.manualCity,
    );
    final mosques = await OverpassMosqueService().nearby(
      lat: loc.lat,
      lon: loc.lon,
    );
    return _MosqueLoad(loc: loc, mosques: mosques);
  }

  Future<void> _toggleFav(Mosque m) async {
    await UserDataRepository.instance.toggleMosqueFavorite(m.favId);
    _favs = await UserDataRepository.instance.mosqueFavorites();
    if (mounted) setState(() {});
  }

  Future<void> _directions(Mosque m) async {
    // Universal geo: URI — opens Google Maps / Apple Maps / OSM app.
    final uri = Uri.parse(
        'geo:${m.lat},${m.lon}?q=${m.lat},${m.lon}(${Uri.encodeComponent(m.name)})');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'common_open_failed'))),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context, 'mosque_title')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: S.of(context, 'mosque_list')),
            Tab(text: S.of(context, 'mosque_map')),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: S.of(context, 'common_refresh'),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // Phase 6: offline indicator (search + map tiles need internet).
          const OfflineBanner(),
          Expanded(
            child: FutureBuilder<_MosqueLoad>(
        future: _loadFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return LoadingView(label: S.of(context, 'mosque_loading'));
          }
          if (snap.hasError || !snap.hasData) {
            return ErrorView(
              message: S.of(context, 'mosque_error'),
              retryLabel: S.of(context, 'common_refresh'),
              onRetry: _load,
            );
          }
          final load = snap.data!;
          if (load.mosques.isEmpty) {
            return ErrorView(
              message: S.of(context, 'mosque_none'),
              retryLabel: S.of(context, 'common_refresh'),
              onRetry: _load,
            );
          }
          return Column(
            children: [
              if (load.loc.usedFallback)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InfoCard(
                    icon: Icons.location_off_outlined,
                    title: S.of(context, 'mosque_fallback_title'),
                    body: S.of(context, 'mosque_fallback_body'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    '${load.mosques.length} · ${load.loc.label}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _listTab(load),
                    _mapTab(load),
                  ],
                ),
              ),
            ],
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTab(_MosqueLoad load) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: load.mosques.length,
      itemBuilder: (context, i) {
        final m = load.mosques[i];
        final km = m.distanceKm(load.loc.lat, load.loc.lon);
        final fav = _favs.contains(m.favId);
        return Card(
          child: ListTile(
            leading: Icon(
              fav ? Icons.mosque : Icons.mosque_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(m.name),
            subtitle: Text(
              '${_fmtKm(km)}${m.address == null ? '' : ' · ${m.address}'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    fav ? Icons.favorite : Icons.favorite_border,
                    color: fav ? Colors.red : null,
                  ),
                  tooltip: S.of(context, 'mosque_favorite'),
                  onPressed: () => _toggleFav(m),
                ),
                IconButton(
                  icon: const Icon(Icons.directions_outlined),
                  tooltip: S.of(context, 'mosque_directions'),
                  onPressed: () => _directions(m),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mapTab(_MosqueLoad load) {
    final center = LatLng(load.loc.lat, load.loc.lon);
    // Phase 6: map tiles need the internet; the OfflineBanner at the
    // top of this screen communicates offline state. Favorite mosques
    // remain available in the list tab offline.
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.nooredeen.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 40,
              height: 40,
              child: const Icon(Icons.my_location,
                  color: Colors.blue, size: 32),
            ),
            for (final m in load.mosques.take(30))
              Marker(
                point: LatLng(m.lat, m.lon),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _directions(m),
                  child: Icon(Icons.mosque,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _fmtKm(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
}

class _MosqueLoad {
  _MosqueLoad({required this.loc, required this.mosques});
  final ResolvedLocation loc;
  final List<Mosque> mosques;
}
