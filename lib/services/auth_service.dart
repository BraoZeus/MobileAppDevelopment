import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Email & Password Sign Up with Verification Link ---
  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      // 1. Create the user account in Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // 2. Send the verification email to the user's inbox
      await userCredential.user?.sendEmailVerification();

      // 3. Sign out immediately so they must log in only after verifying
      await _auth.signOut();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- Google Sign-In v7.0+ ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final List<String> scopes = ['email', 'profile'];
      final clientAuth = await googleUser.authorizationClient.authorizeScopes(scopes);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: clientAuth.accessToken,
      );

      return await _auth.signInWithCredential(credential);

    } catch (e) {
      throw Exception('Failed to sign in with Google. Please try again.');
    }
  }

  // --- Sign Out ---
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  // --- Auth State Stream ---
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}