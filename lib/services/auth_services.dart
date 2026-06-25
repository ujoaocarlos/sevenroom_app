import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();

  Stream<User?> get userStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // E-mail/senha
  Future<void> registerWithEmail(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user!;
      await user.updateDisplayName(name);
      await _saveUserDocument(user, name);
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

  // Google Sign-In (web: popup, Android/iOS: google_sign_in package)
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Para web: usa popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        final UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        final User user = userCredential.user!;
        final existingUser = await _userRepository.fetchById(user.uid);
        if (existingUser == null) {
          await _saveUserDocument(user, user.displayName ?? user.email?.split('@').first ?? 'Usuário');
        }
        return user;
      } else {
        // Para Android/iOS: usa google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User user = userCredential.user!;
        final existingUser = await _userRepository.fetchById(user.uid);
        if (existingUser == null) {
          await _saveUserDocument(user, user.displayName ?? user.email?.split('@').first ?? 'Usuário');
        }
        return user;
      }
    } catch (e) {
      throw Exception('Erro no login com Google: $e');
    }
  }

  // Microsoft (opcional)
  Future<User?> signInWithMicrosoft() async {
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.addScope('email');
      provider.addScope('openid');
      provider.addScope('profile');
      provider.setCustomParameters({'tenant': 'common'});
      final UserCredential userCredential = await _auth.signInWithPopup(provider);
      final User user = userCredential.user!;
      final existingUser = await _userRepository.fetchById(user.uid);
      if (existingUser == null) {
        await _saveUserDocument(user, user.displayName ?? user.email?.split('@').first ?? 'Usuário Microsoft');
      }
      return user;
    } catch (e) {
      throw Exception('Erro ao entrar com Microsoft: $e');
    }
  }

  // Admin
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    final appUser = await _userRepository.fetchById(user.uid);
    return appUser?.role == 'admin';
  }

  Future<AppUser?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;
    return await _userRepository.fetchById(user.uid);
  }

  Future<void> updateUserName(String newName) async {
    final user = currentUser;
    if (user == null) return;
    await user.updateDisplayName(newName);
    final appUser = await _userRepository.fetchById(user.uid);
    if (appUser != null) {
      final updatedUser = AppUser(
        uid: appUser.uid,
        nome: newName,
        email: appUser.email,
        role: appUser.role,
        createdAt: appUser.createdAt,
      );
      await _userRepository.save(updatedUser);
    } else {
      await _saveUserDocument(user, newName);
    }
  }

  Future<void> _saveUserDocument(User user, String name) async {
    final appUser = AppUser(
      uid: user.uid,
      nome: name.trim(),
      email: user.email ?? '',
      role: 'user',
    );
    await _userRepository.save(appUser);
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _auth.signOut();
      } else {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
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
      default: return 'Erro: ${e.message}';
    }
  }
}