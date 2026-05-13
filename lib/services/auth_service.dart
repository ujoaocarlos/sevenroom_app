import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get userStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ---------- E-mail/Senha ----------
  Future<void> registerWithEmail(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'nome': name,
        'email': email.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    }
  }

  // ---------- Google (Web: signInWithPopup) ----------
  Future<User?> signInWithGoogle() async {
    try {
      // Usando Firebase Auth com popup - funciona perfeitamente na Web
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      final User user = userCredential.user!;
      
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'nome': user.displayName ?? '',
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print('Erro no login com Google (popup): $e');
      throw Exception('Erro no login com Google: $e');
    }
  }

  // ---------- Google (Alternativo para Mobile) ----------
  // Este método é mantido para compatibilidade com Android/iOS
  Future<User?> signInWithGoogleMobile() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'nome': user.displayName ?? '',
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      throw Exception('Erro no login com Google: $e');
    }
  }

  // ---------- Microsoft (compatível com Web via signInWithPopup) ----------
  Future<User?> signInWithMicrosoft() async {
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.addScope('email');
      provider.addScope('openid');
      provider.addScope('profile');
      provider.setCustomParameters({
        'tenant': 'common',
      });

      final UserCredential userCredential = await _auth.signInWithPopup(provider);
      final User user = userCredential.user!;

      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'nome': user.displayName ?? user.email?.split('@').first ?? 'Usuário Microsoft',
          'email': user.email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      throw Exception('Erro ao entrar com Microsoft: $e');
    }
  }

  // ---------- Admin / Perfil / Logout ----------
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> updateUserName(String newName) async {
    final user = currentUser;
    if (user == null) return;
    await user.updateDisplayName(newName);
    await _firestore.collection('users').doc(user.uid).update({'nome': newName});
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _getAuthErrorMessage(e);
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'Este e-mail já está cadastrado.';
      case 'weak-password': return 'A senha é muito fraca.';
      case 'user-not-found': return 'Usuário não encontrado.';
      case 'wrong-password': return 'Senha incorreta.';
      case 'invalid-email': return 'E-mail inválido.';
      default: return 'Erro: ${e.message}';
    }
  }
}