import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_recycle/pages/authentication/signup.dart';
import 'package:smart_recycle/services/auth_service.dart';
import 'package:smart_recycle/pages/user/home_user.dart';
import 'package:smart_recycle/pages/admin/home_admin.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Contrôleurs pour récupérer les valeurs saisies dans les champs texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instance du service d’authentification
  final AuthService _authService = AuthService();

  // Variable d'état pour afficher/masquer le mot de passe
  bool _obscurePassword = true;

  // Variable d'état pour le chargement
  bool _isLoading = false;

  // Libération des ressources lorsque le widget est détruit
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Evite que le clavier cache les champs
      resizeToAvoidBottomInset: true,

      // Lien vers la page d'inscription en bas de l'écran
      bottomNavigationBar: _signup(context),

      // AppBar transparente avec bouton de retour
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              color: Color(0xffF7F7F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
          ),
        ),
      ),

      // Contenu principal
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              // Titre de la page
              Center(
                child: Text(
                  'Un plaisir de vous revoir !',
                  style: GoogleFonts.raleway(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Champ email
              const SizedBox(height: 80),
              _emailAddress(),
              // Champ mot de passe
              const SizedBox(height: 20),
              _password(),
              // Bouton de connexion
              const SizedBox(height: 50),
              _signin(context),
            ],
          ),
        ),
      ),
    );
  }

  // Champ saisie de l'adresse email
  Widget _emailAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Adresse mail', style: GoogleFonts.raleway(fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            filled: true,
            hintText: 'exemple@email.com',
            fillColor: const Color(0xffF7F7F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // Champ saisie du mot de passe
  Widget _password() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mot de passe', style: GoogleFonts.raleway(fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword, // Affiche/Masque le mot de passe
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF7F7F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Bouton de connexion
  Widget _signin(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0D6EFD),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      // Vérification des champs vides
      onPressed: () async {
        if (_emailController.text.trim().isEmpty || 
            _passwordController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez remplir tous les champs')),
          );
          return;
        }

        setState(() => _isLoading = true); // démarre le chargement

        // Appel du service d'authentification
        final result = await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        setState(() => _isLoading = false); // arrêter le chargement

        // Gestion des erreurs
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur inconnue lors de la connexion')),
          );
          return;
        }

        if (result['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'])),
          );
          return;
        }

        // Vérifier que le rôle est présent
        final role = result['role'] as String?;
        if (role == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rôle utilisateur introuvable')),
          );
          return;
        }

        // Rediriger selon le rôle (admin/user)
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeAdmin()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomeUser()),
          );
        }
      },
      child: _isLoading
      ? const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 2,
      ),
    )
        : const Text("Se connecter", style: TextStyle(color: Colors.white)),
    );
  }

  Widget _signup(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Nouveau sur l'application ? ",
              style: TextStyle(color: Color(0xff6A6A6A), fontSize: 16),
            ),
            TextSpan(
              text: "Créer un compte",
              style: const TextStyle(
                color: Color(0xff1A1D1E),
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Signup()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
