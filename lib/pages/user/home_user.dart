import 'package:flutter/material.dart';
import 'package:smart_recycle/services/auth_service.dart';
import 'package:smart_recycle/pages/authentication/login.dart';
import 'package:smart_recycle/pages/user/map_bins.dart';

class HomeUser extends StatelessWidget {
  HomeUser({super.key});
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Smart Bin Tracker'),
        actions: [
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout(); // utilise la méthode logout du service
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
        body: const MapBinsPage(),
    );
  }
}
