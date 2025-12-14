import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_recycle/models/smart_bin.dart';
import 'package:smart_recycle/mock/mock_bins.dart';

class MapBinsPage extends StatefulWidget {
  const MapBinsPage({super.key});

  @override
  State<MapBinsPage> createState() => _MapBinsPageState();
}

class _MapBinsPageState extends State<MapBinsPage> {
  final LatLng _initialPosition = LatLng(-20.1609, 57.5012);

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

  // Crée les markers à partir des mockBins
  List<Marker> _buildMarkers() {
    return mockBins.map((bin) {
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
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
    return FlutterMap(
        options: MapOptions(
          center: _initialPosition,
          zoom: 14,
          maxZoom: 18,
          minZoom: 3,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.smart_recycle',
          ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
    );
  }
}
