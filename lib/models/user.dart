import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String nome;
  final String email;
  final String role;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.nome,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      nome: map['nome'] as String? ?? 'Usuário',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'role': role,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
