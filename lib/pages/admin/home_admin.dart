import 'package:flutter/material.dart';
import 'package:smart_recycle/services/auth_service.dart';
import 'package:smart_recycle/pages/authentication/login.dart';

class HomeAdmin extends StatelessWidget {
  HomeAdmin({super.key});
  final AuthService _authService = AuthService(); // service

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout(); // utilise la méthode du service
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Bienvenue, Administrateur !')),
    );
  }
}
