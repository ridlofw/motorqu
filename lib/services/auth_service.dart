import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      // Pengguna membatalkan dialog pemilihan akun Google
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Di Android, idToken adalah kunci utama yang diperlukan oleh Firebase.
    // accessToken bisa jadi null pada beberapa versi Google Play Services.
    if (googleAuth.idToken == null && googleAuth.accessToken == null) {
      throw Exception('Gagal mengambil kredensial Google (Token tidak tersedia)');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // Sinkronkan profil user ke Firestore secara non-blocking agar tidak menahan/memperlambat alur login
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      userDoc.set({
        'uid': user.uid,
        'displayName': user.displayName ?? 'Pengguna',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {
        // Abaikan error jaringan profil agar alur login tetap berhasil masuk
      });
    }

    return user;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
  }
}
