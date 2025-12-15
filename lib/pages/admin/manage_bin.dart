import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum BinCategory { plastic, organic, electronic, paper, bottle }

class ManageBinsPage extends StatefulWidget {
  const ManageBinsPage({super.key});

  @override
  State<ManageBinsPage> createState() => _ManageBinsPageState();
}

class _ManageBinsPageState extends State<ManageBinsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Pour le formulaire d'ajout
  final TextEditingController _nameController = TextEditingController();
  // Set pour éviter les doublons de catégories
  final Set<BinCategory> _selectedCategories = {};
  LatLng? _selectedPosition;

  // Pour afficher la map
  final LatLng _initialPosition = LatLng(-20.1609, 57.5012);
  Marker? _tempMarker;

  // Liste des bacs
  Stream<QuerySnapshot> get _binsStream =>
      _firestore.collection('bins').snapshots();

  void _showAddBinDialog() {
    // On réinitialise les catégories sélectionnées à chaque ouverture
    _selectedCategories.clear();

    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un emplacement sur la carte')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un bac'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du bac'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: BinCategory.values.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat.name),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedCategories.add(cat); // Set => pas de doublon
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Catégories sélectionnées : ${_selectedCategories.map((c) => c.name).join(', ')}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _selectedCategories.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Remplissez tous les champs')),
                );
                return;
              }

              try {
                await _firestore.collection('bins').add({
                  'name': _nameController.text.trim(),
                  'categories':
                      _selectedCategories.map((e) => e.name).toList(),
                  'latitude': _selectedPosition!.latitude,
                  'longitude': _selectedPosition!.longitude,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Erreur lors de l\'ajout du bac (permissions Firestore ?) : $e',
                    ),
                  ),
                );
                return;
              }

              _nameController.clear();
              _selectedCategories.clear();
              setState(() {
                _tempMarker = null;
                _selectedPosition = null;
              });

              Navigator.pop(context);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(List categories) {
    if (categories.contains('plastic')) return Colors.blue;
    if (categories.contains('organic')) return Colors.green;
    if (categories.contains('electronic')) return Colors.purple;
    if (categories.contains('paper')) return Colors.brown;
    if (categories.contains('bottle')) return Colors.cyan;
    return Colors.red;
  }

  void _showEditBinDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final TextEditingController editNameController =
        TextEditingController(text: data['name'] ?? '');

    // Copie locale des catégories existantes sous forme de Set<BinCategory>
    final Set<BinCategory> editSelectedCategories = {};
    if (data['categories'] is List) {
      for (final dynamic c in (data['categories'] as List)) {
        if (c is String) {
          try {
            final cat = BinCategory.values.firstWhere(
              (e) => e.name == c,
              orElse: () => BinCategory.plastic,
            );
            editSelectedCategories.add(cat);
          } catch (_) {
            // Ignore les valeurs inconnues
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) {
          return AlertDialog(
            title: const Text('Modifier le bac'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editNameController,
                  decoration: const InputDecoration(labelText: 'Nom du bac'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: BinCategory.values.map((cat) {
                    final selected = editSelectedCategories.contains(cat);
                    return FilterChip(
                      label: Text(cat.name),
                      selected: selected,
                      onSelected: (val) {
                        setLocalState(() {
                          if (val) {
                            editSelectedCategories.add(cat);
                          } else {
                            editSelectedCategories.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Catégories sélectionnées : ${editSelectedCategories.map((c) => c.name).join(', ')}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (editNameController.text.isEmpty ||
                      editSelectedCategories.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Remplissez tous les champs'),
                      ),
                    );
                    return;
                  }

                  try {
                    await _firestore.collection('bins').doc(doc.id).update({
                      'name': editNameController.text.trim(),
                      'categories': editSelectedCategories
                          .map((e) => e.name)
                          .toList(),
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Erreur lors de la modification du bac : $e'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                center: _initialPosition,
                zoom: 14,
                onTap: (tapPos, latlng) {
                  setState(() {
                    _selectedPosition = latlng;
                    _tempMarker = Marker(
                      point: latlng,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    );
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.smart_recycle',
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: _binsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final docs = snapshot.data!.docs;
                    return MarkerLayer(
                      markers: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Marker(
                          point:
                              LatLng(data['latitude'], data['longitude']),
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.location_on,
                            color: _categoryColor(data['categories']),
                            size: 40,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                if (_tempMarker != null)
                  MarkerLayer(
                    markers: [_tempMarker!],
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: StreamBuilder<QuerySnapshot>(
              stream: _binsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Aucun bac ajouté'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name']),
                      subtitle:
                          Text((data['categories'] as List).join(', ')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditBinDialog(docs[index]);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Supprimer le bac'),
                                  content: const Text(
                                      'Voulez-vous vraiment supprimer ce bac ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Supprimer',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _firestore
                                    .collection('bins')
                                    .doc(docs[index].id)
                                    .delete();
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBinDialog,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Gestion des bacs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
