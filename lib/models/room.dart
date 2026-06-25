import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String? id;
  final String nome;
  final String tipo;
  final int capacidade;
  final String local;
  final bool disponivel;
  final double taxaPorTurno;
  final bool bloquearNoturno;
  final bool exigeAutorizacaoFimSemana;
  final bool exigeAutorizacaoSempre;
  final DateTime? createdAt;

  Room({
    this.id,
    required this.nome,
    required this.tipo,
    required this.capacidade,
    required this.local,
    required this.disponivel,
    required this.taxaPorTurno,
    required this.bloquearNoturno,
    required this.exigeAutorizacaoFimSemana,
    required this.exigeAutorizacaoSempre,
    this.createdAt,
  });

  factory Room.fromMap(Map<String, dynamic> map, {String? id}) {
    return Room(
      id: id,
      nome: map['nome'] as String? ?? 'Sem nome',
      tipo: map['tipo'] as String? ?? 'sala',
      capacidade: map['capacidade'] is int
          ? map['capacidade'] as int
          : int.tryParse('${map['capacidade']}') ?? 0,
      local: map['local'] as String? ?? 'Local não informado',
      disponivel: map['disponivel'] as bool? ?? true,
      taxaPorTurno: map['taxaPorTurno'] is double
          ? map['taxaPorTurno'] as double
          : double.tryParse('${map['taxaPorTurno']}') ?? 0.0,
      bloquearNoturno: map['bloquearNoturno'] as bool? ?? false,
      exigeAutorizacaoFimSemana: map['exigeAutorizacaoFimSemana'] as bool? ?? false,
      exigeAutorizacaoSempre: map['exigeAutorizacaoSempre'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'capacidade': capacidade,
      'local': local,
      'disponivel': disponivel,
      'taxaPorTurno': taxaPorTurno,
      'bloquearNoturno': bloquearNoturno,
      'exigeAutorizacaoFimSemana': exigeAutorizacaoFimSemana,
      'exigeAutorizacaoSempre': exigeAutorizacaoSempre,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
