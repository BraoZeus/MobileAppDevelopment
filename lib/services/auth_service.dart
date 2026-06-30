import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton instance for Google Sign In (v7.0.0+)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  // Flag to ensure initialization happens only once
  bool _isInitialized = false;

  /// Ensures GoogleSignIn is correctly configured for Android/Firebase.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      try {
        await _googleSignIn.initialize(
          // Web Client ID (Required as serverClientId for Firebase ID tokens)
          serverClientId: '1061936059311-f8h6oa88sei6ms3ojececqbqurqsh33k.apps.googleusercontent.com',
          // Android Client ID (Recommended for configuration stability)
          clientId: '1061936059311-3m8sf64kqalbjsgvibntmghkjd2omu7k.apps.googleusercontent.com',
        );
        _isInitialized = true;
      } catch (e) {
        // If already initialized, ignore the error
        if (e.toString().contains('already initialized')) {
          _isInitialized = true;
        } else {
          rethrow;
        }
      }
    }
  }

// Email & Password Sign Up with Verification Link
  Future<void> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await userCredential.user?.sendEmailVerification();
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

// Google Sign-In (Compatible with v7.2.0)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 0. Ensure initialization is complete before proceeding
      await _ensureInitialized();

      // 1. Trigger the Google Authentication flow
      // authenticate() replaces the old signIn() in v7.0.0+
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Obtain the auth details (synchronous property in v7.x — no await)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Create a Firebase credential using idToken only (accessToken not
      //    available in basic auth flow in google_sign_in v7.x)
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      return await _auth.signInWithCredential(credential);

    } catch (e) {
      // Return null if the user canceled the sign-in
      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      throw Exception('Google Sign-In failed: $e');
    }
  }

// Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

// Auth State Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
