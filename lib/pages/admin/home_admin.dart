import 'package:flutter/material.dart';
import 'package:smart_recycle/services/auth_service.dart';
import 'package:smart_recycle/pages/authentication/login.dart';
import 'package:smart_recycle/pages/admin/map_bins.dart';
import 'package:smart_recycle/pages/admin/manage_bin.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Smart Bin Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Carte", icon: Icon(Icons.map)),
            Tab(text: "Ajouter Bac", icon: Icon(Icons.add_location)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          MapBinsPage(),
          ManageBinsPage(),
        ],
      ),
    );
  }
}
