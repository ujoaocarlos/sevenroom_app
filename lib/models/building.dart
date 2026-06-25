import 'package:cloud_firestore/cloud_firestore.dart';

class Building {
  final String? id;
  final String nome;
  final String endereco;
  final int andares;
  final List<String> roomIds;
  final DateTime? createdAt;

  Building({
    this.id,
    required this.nome,
    required this.endereco,
    required this.andares,
    required this.roomIds,
    this.createdAt,
  });

  factory Building.fromMap(Map<String, dynamic> map, {String? id}) {
    return Building(
      id: id,
      nome: map['nome'] as String? ?? 'Prédio sem nome',
      endereco: map['endereco'] as String? ?? 'Endereço não informado',
      andares: map['andares'] is int
          ? map['andares'] as int
          : int.tryParse('${map['andares']}') ?? 0,
      roomIds: List<String>.from(map['roomIds'] as List<dynamic>? ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'endereco': endereco,
      'andares': andares,
      'roomIds': roomIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
