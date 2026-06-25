import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservation.dart';

class ReservationConflictException implements Exception {
  final String message;

  const ReservationConflictException([
    this.message = 'Esta sala já está reservada para o horário selecionado.',
  ]);

  @override
  String toString() => message;
}

class ReservationRepository {
  final CollectionReference _reservations =
      FirebaseFirestore.instance.collection('reservations');
  final CollectionReference _reservationLocks =
      FirebaseFirestore.instance.collection('reservationLocks');

  Stream<List<Reservation>> userReservationsStream(String userId) =>
      _reservations
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map(_mapAndSort);

  Stream<List<Reservation>> allReservationsStream({String? statusFilter}) {
    Query query = _reservations.orderBy('data', descending: true);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map(_mapAndSort);
  }

  Future<List<Reservation>> getActiveReservationsForRoomAndDate(
    String roomDocId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final querySnapshot = await _reservations
        .where('roomDocId', isEqualTo: roomDocId)
        .where('data', isEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    return querySnapshot.docs
        .map(
          (doc) => Reservation.fromMap(
            doc.data() as Map<String, dynamic>,
            id: doc.id,
          ),
        )
        .where((res) => res.status != 'cancelado' && res.status != 'recusado')
        .toList();
  }

  Future<Reservation> add(Reservation reservation) async {
    return addIfNoConflict(reservation);
  }

  Future<Reservation> addIfNoConflict(Reservation reservation) async {
    if (reservation.data == null ||
        reservation.horaInicio == null ||
        reservation.horaFim == null) {
      throw ArgumentError(
        'Reservation date, start time and end time are required.',
      );
    }

    final lockIds = _lockIdsForReservation(reservation);
    final reservationRef = _reservations.doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      for (final lockId in lockIds) {
        final lockSnapshot = await transaction.get(
          _reservationLocks.doc(lockId),
        );
        if (lockSnapshot.exists) {
          final data = lockSnapshot.data() as Map<String, dynamic>;
          if (data['active'] == true) {
            throw const ReservationConflictException();
          }
        }
      }

      transaction.set(reservationRef, reservation.toMap());
      for (final lockId in lockIds) {
        transaction.set(_reservationLocks.doc(lockId), {
          'reservationId': reservationRef.id,
          'roomDocId': reservation.roomDocId,
          'userId': reservation.userId,
          'data': Timestamp.fromDate(reservation.data!),
          'horaInicio': Timestamp.fromDate(reservation.horaInicio!),
          'horaFim': Timestamp.fromDate(reservation.horaFim!),
          'status': reservation.status,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });

    return Reservation(
      id: reservationRef.id,
      roomId: reservation.roomId,
      roomDocId: reservation.roomDocId,
      userId: reservation.userId,
      responsavelNome: reservation.responsavelNome,
      status: reservation.status,
      data: reservation.data,
      horaInicio: reservation.horaInicio,
      horaFim: reservation.horaFim,
      createdAt: reservation.createdAt,
      email: reservation.email,
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final releasesSlot = status == 'cancelado' || status == 'recusado';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_reservations.doc(id), {'status': status});

    final locksSnapshot =
        await _reservationLocks.where('reservationId', isEqualTo: id).get();

    for (final doc in locksSnapshot.docs) {
      if (releasesSlot) {
        batch.delete(doc.reference);
      } else {
        batch.update(doc.reference, {
          'status': status,
          'active': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();
  }

  Future<void> cancel(String id) async {
    await updateStatus(id, 'cancelado');
  }

  Future<void> delete(String id) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_reservations.doc(id));

    final locksSnapshot =
        await _reservationLocks.where('reservationId', isEqualTo: id).get();

    for (final doc in locksSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  List<Reservation> _mapAndSort(QuerySnapshot snapshot) {
    final reservations = snapshot.docs
        .map((doc) =>
            Reservation.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
        .toList();
    reservations.sort((a, b) {
      final aDate = a.data ?? a.createdAt ?? DateTime.now();
      final bDate = b.data ?? b.createdAt ?? DateTime.now();
      return bDate.compareTo(aDate);
    });
    return reservations;
  }

  List<String> _lockIdsForReservation(Reservation reservation) {
    final start = reservation.horaInicio!;
    final end = reservation.horaFim!;
    final firstSlot = DateTime(
      start.year,
      start.month,
      start.day,
      start.hour,
      start.minute < 30 ? 0 : 30,
    );
    final ids = <String>[];

    for (var slot = firstSlot;
        slot.isBefore(end);
        slot = slot.add(const Duration(minutes: 30))) {
      ids.add('${reservation.roomDocId}_${_dateKey(slot)}_${_timeKey(slot)}');
    }

    return ids;
  }

  String _dateKey(DateTime date) =>
      '${date.year}${_two(date.month)}${_two(date.day)}';

  String _timeKey(DateTime time) => '${_two(time.hour)}${_two(time.minute)}';

  String _two(int value) => value.toString().padLeft(2, '0');
}
