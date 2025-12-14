import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // ← ajouter ça

  // Signup avec rôle
  Future<String?> signup({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      // Stocker la réponse dans cred
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ajouter l'utilisateur dans Firestore avec rôle
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'email': email,
        'role': role,
      });

      return null; // succès
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Mot de passe trop faible';
      if (e.code == 'email-already-in-use') return 'Un compte existe déjà avec cet email';
      if (e.code == 'invalid-email') return 'Email invalide';
      return 'Erreur : ${e.code}';
    }
  }

  // Login et récupération du rôle
  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Récupérer le rôle depuis Firestore
      final doc = await _firestore.collection('users').doc(cred.user!.uid).get();

      if (!doc.exists) {
        // Si le document n'existe pas, créer un document par défaut avec rôle 'user'
        await _firestore.collection('users').doc(cred.user!.uid).set({
          'email': email,
          'role': 'user',
        });
        return {'uid': cred.user!.uid, 'role': 'user'};
      }
      
      final data = doc.data();
      if (data == null) {
        return {'error': 'Données utilisateur introuvables'};
      }
      
      final role = data['role'] ?? 'user';
      return {'uid': cred.user!.uid, 'role': role};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return {'error': 'Utilisateur introuvable'};
      if (e.code == 'wrong-password') return {'error': 'Mot de passe incorrect'};
      if (e.code == 'invalid-email') return {'error': 'Email invalide'};
      return {'error': e.code};
    } catch (e) {
      return {'error': 'Erreur lors de la connexion: ${e.toString()}'};
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
