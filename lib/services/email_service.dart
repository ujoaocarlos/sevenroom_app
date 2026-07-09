import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/reservation.dart';

class EmailService {
  static const String _apiBaseUrl = String.fromEnvironment(
    'EMAIL_API_BASE_URL',
    defaultValue: 'https://sevenroom-email-api.onrender.com',
  );

  bool get isConfigured => _apiBaseUrl.isNotEmpty;

  Future<void> sendReservationCreatedEmail(Reservation reservation) async {
    if (reservation.status == 'aprovado') {
      await _sendReservationEmail(
        template: 'reservation_created',
        reservation: reservation,
      );
      return;
    }

    await _sendReservationEmail(
      template: 'reservation_created',
      reservation: reservation,
    );
  }

  Future<void> sendReservationApprovedEmail(Reservation reservation) async {
    await _sendReservationEmail(
      template: 'reservation_approved',
      reservation: reservation,
    );
  }

  Future<void> _sendReservationEmail({
    required String template,
    required Reservation reservation,
  }) async {
    final email = reservation.email;
    if (!isConfigured || email == null || email.trim().isEmpty) {
      return;
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('$_apiBaseUrl/api/email/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'template': template,
        'reservation': _reservationPayload(reservation),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha ao enviar e-mail (${response.statusCode}).');
    }
  }

  Map<String, dynamic> _reservationPayload(Reservation reservation) {
    return {
      'id': reservation.id,
      'roomId': reservation.roomId,
      'roomDocId': reservation.roomDocId,
      'userId': reservation.userId,
      'responsavelNome': reservation.responsavelNome,
      'status': reservation.status,
      'data': reservation.data?.toIso8601String(),
      'horaInicio': reservation.horaInicio?.toIso8601String(),
      'horaFim': reservation.horaFim?.toIso8601String(),
      'email': reservation.email,
    };
  }
}
