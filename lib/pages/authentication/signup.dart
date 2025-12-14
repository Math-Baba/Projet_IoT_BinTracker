import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_recycle/pages/authentication/login.dart';
import 'package:smart_recycle/services/auth_service.dart';
import 'package:smart_recycle/pages/authentication/login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Contrôleurs pour récupérer les valeurs saisies dans les champs texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Instance du service d’authentification
  final AuthService _authService = AuthService();

  // Variable d'état pour afficher/masquer le mot de passe
  bool _obscurePassword = true;

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
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: _signin(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Center(
                child: Text(
                  'Inscription',
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
              // Bouton d'inscription
              const SizedBox(height: 50),
              _signup(context),
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
        Text('Adresse Email', style: GoogleFonts.raleway(fontSize: 16)),
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

  // Champ mot de passe
  Widget _password() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mot de passe', style: GoogleFonts.raleway(fontSize: 16)),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword, // Affiche ou Masque le mot de passe
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF7F7F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            // Bouton pour masquer/afficher le mot de passe
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

  // Bouton d'inscription
  Widget _signup(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0D6EFD),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: () async {
        final error = await _authService.signup(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: 'user', // rôle user par défaut
        );

        // Affiche une erreur si l'inscription échoue
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Redirige vers la page de connexion en cas de succès
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => Login()),
          );
        }
      },
      child: const Text("S'inscrire", style: TextStyle(color: Colors.white)),
    );
  }

  // Lien de redirection vers la page de connexion
  Widget _signin(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: "Vous avez déjà un compte ? ",
              style: TextStyle(color: Color(0xff6A6A6A), fontSize: 16),
            ),
            TextSpan(
              text: "Se connecter",
              style: const TextStyle(
                color: Color(0xff1A1D1E),
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  );
                },
            ),
          ],
        ),
      ),
    );
  }
}
