import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_recycle/models/smart_bin.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smart_recycle/services/route_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapBinsPage extends StatefulWidget {
  const MapBinsPage({super.key});

  @override
  State<MapBinsPage> createState() => _MapBinsPageState();
}

class _MapBinsPageState extends State<MapBinsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LatLng _initialPosition = LatLng(-20.1609, 57.5012);

  LatLng? _userPosition;
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<BinCategory> _tempSelectedCategories = {};
  Set<BinCategory> _appliedCategories = {};

  /// Centres approximatifs de quelques régions (clés en minuscules)
  final Map<String, LatLng> _regionCenters = {
    'port louis': LatLng(-20.1609, 57.5012),
    'grand baie': LatLng(-20.0130, 57.5800),
    'curepipe': LatLng(-20.3170, 57.5250),
    'quatre bornes': LatLng(-20.2633, 57.4791),
    'rose hill': LatLng(-20.2350, 57.4820),
    'vacoas': LatLng(-20.2980, 57.4780),
    'flic en flac': LatLng(-20.2796, 57.3653),
    'mahebourg': LatLng(-20.4081, 57.7000),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Convertit la liste de catégories en texte
  String _categoriesToText(List<BinCategory> categories) {
    return categories.map((c) => c.name).join(', ');
  }

  // Détermine la couleur de l'icône selon la catégorie
  Color _categoryColor(List<BinCategory> categories) {
    if (categories.contains(BinCategory.plastic)) return Colors.blue;
    if (categories.contains(BinCategory.organic)) return Colors.green;
    if (categories.contains(BinCategory.electronic)) return Colors.purple;
    if (categories.contains(BinCategory.paper)) return Colors.brown;
    if (categories.contains(BinCategory.bottle)) return Colors.cyan;
    return Colors.red;
  }

  // Libellé lisible pour chaque catégorie
  String _singleCategoryToText(BinCategory category) {
    switch (category) {
      case BinCategory.plastic:
        return 'Plastic';
      case BinCategory.bag:
        return 'Bag';
      case BinCategory.electronic:
        return 'Electronic';
      case BinCategory.organic:
        return 'Organic';
      case BinCategory.paper:
        return 'Paper';
      case BinCategory.bottle:
        return 'Bottle';
    }
  }

  // Transforme un document Firestore en SmartBin (region facultative)
  SmartBin _binFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final List<dynamic> rawCategories =
    (data['categories'] as List<dynamic>? ?? []);
    final List<BinCategory> categories = [];
    for (final dynamic c in rawCategories) {
      if (c is String) {
        try {
          final cat = BinCategory.values
              .firstWhere((e) => e.name == c, orElse: () => BinCategory.plastic);
          if (!categories.contains(cat)) {
            categories.add(cat);
          }
        } catch (_) {
          // ignore catégorie inconnue
        }
      }
    }

    return SmartBin(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Bac',
      region: (data['region'] as String?) ?? 'Inconnue',
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      category: categories,
    );
  }

  // Applique le filtre de catégories aux bacs récupérés
  List<SmartBin> _applyCategoryFilter(List<SmartBin> bins) {
    return bins.where((bin) {
      final matchesCategory = _appliedCategories.isEmpty ||
          bin.category.any((c) => _appliedCategories.contains(c));
      return matchesCategory;
    }).toList();
  }

  // Centre et zoome la carte sur une région connue (nom, sans tenir compte de la casse)
  void _zoomToRegionByName(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return;

    // Recherche d'abord une correspondance exacte, puis une correspondance contenant le texte
    LatLng? target;
    if (_regionCenters.containsKey(normalized)) {
      target = _regionCenters[normalized];
    } else {
      for (final entry in _regionCenters.entries) {
        if (entry.key.contains(normalized)) {
          target = entry.value;
          break;
        }
      }
    }

    if (target == null) return;

    _mapController.move(target, 15);
  }

  Future<void> _getUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = LatLng(pos.latitude, pos.longitude);
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Crée les markers à partir des bacs filtrés
  List<Marker> _buildMarkers(List<SmartBin> bins) {
    final binsToShow = _applyCategoryFilter(bins);
    return binsToShow.map((bin) {
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(bin.latitude, bin.longitude),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Bac intelligent'),
                content: Text(_categoriesToText(bin.category)),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      if (_userPosition == null) return;

                      final route = await RouteService.getRoute(
                        _userPosition!,
                        LatLng(bin.latitude, bin.longitude),
                      );

                      setState(() {
                        _routePoints = route;
                      });
                    },
                    child: const Text('Itinéraire'),
                  ),
                ],
              ),
            );
          },

          child: Icon(
            Icons.location_on,
            color: _categoryColor(bin.category),
            size: 40,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une région',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              _zoomToRegionByName(value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ExpansionTile(
            title: const Text('Filtres catégories'),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: BinCategory.values.map((category) {
                  final selected = _tempSelectedCategories.contains(category);
                  return FilterChip(
                    label: Text(_singleCategoryToText(category)),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _tempSelectedCategories.add(category);
                        } else {
                          _tempSelectedCategories.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _tempSelectedCategories.clear();
                        _appliedCategories.clear();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _appliedCategories = {..._tempSelectedCategories};
                      });
                    },
                    child: const Text('Appliquer'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('bins').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('Aucun bac disponible pour le moment'),
                );
              }

              final bins = snapshot.data!.docs
                  .map((doc) => _binFromDoc(doc))
                  .toList();

              return FlutterMap(
                options: MapOptions(
                  center: _initialPosition,
                  zoom: 14,
                  maxZoom: 18,
                  minZoom: 3,
                ),
                mapController: _mapController,
                children: [
                  TileLayer(
                    urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.smart_recycle',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(bins),
                  ),
                  CurrentLocationLayer(
                    alignPositionOnUpdate: AlignOnUpdate.once,
                    alignDirectionOnUpdate: AlignOnUpdate.never,
                    style: const LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        child: Icon(Icons.navigation, color: Colors.white),
                      ),
                      markerSize: Size(40, 40),
                      markerDirection: MarkerDirection.heading,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
