import 'package:cloud_firestore/cloud_firestore.dart';

class Reservation {
  final String? id;
  final String roomId;
  final String roomDocId;
  final String userId;
  final String responsavelNome;
  final String status;
  final DateTime? data;
  final DateTime? horaInicio;
  final DateTime? horaFim;
  final DateTime? createdAt;
  final String? email;

  Reservation({
    this.id,
    required this.roomId,
    required this.roomDocId,
    required this.userId,
    required this.responsavelNome,
    required this.status,
    this.data,
    this.horaInicio,
    this.horaFim,
    this.createdAt,
    this.email,
  });

  factory Reservation.fromMap(Map<String, dynamic> map, {String? id}) {
    Timestamp? parseTimestamp(Object? value) {
      if (value is Timestamp) return value;
      return null;
    }

    return Reservation(
      id: id,
      roomId: map['roomId'] as String? ?? 'Sala sem nome',
      roomDocId: map['roomDocId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      responsavelNome: map['responsavelNome'] as String? ?? 'Usuário',
      status: map['status'] as String? ?? 'pendente',
      data: parseTimestamp(map['data'])?.toDate(),
      horaInicio: parseTimestamp(map['horaInicio'])?.toDate(),
      horaFim: parseTimestamp(map['horaFim'])?.toDate(),
      createdAt: parseTimestamp(map['createdAt'])?.toDate(),
      email: map['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomDocId': roomDocId,
      'userId': userId,
      'responsavelNome': responsavelNome,
      'status': status,
      'data': data != null ? Timestamp.fromDate(data!) : null,
      'horaInicio': horaInicio != null ? Timestamp.fromDate(horaInicio!) : null,
      'horaFim': horaFim != null ? Timestamp.fromDate(horaFim!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'email': email,
    };
  }
}
