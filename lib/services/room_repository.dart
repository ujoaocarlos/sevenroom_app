import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class RoomRepository {
  final CollectionReference _rooms =
      FirebaseFirestore.instance.collection('rooms');

  Stream<List<Room>> roomsStream() => _rooms.snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => Room.fromMap(doc.data() as Map<String, dynamic>,
                id: doc.id))
            .toList(),
      );

  Future<Room?> getById(String id) async {
    final doc = await _rooms.doc(id).get();
    if (!doc.exists) return null;
    return Room.fromMap(doc.data() as Map<String, dynamic>, id: doc.id);
  }

  Future<void> add(Room room) async {
    await _rooms.add(room.toMap());
  }

  Future<void> update(Room room) async {
    if (room.id == null) {
      throw ArgumentError('Room id is required to update a room.');
    }
    await _rooms.doc(room.id).update(room.toMap());
  }

  Future<void> delete(String id) async {
    await _rooms.doc(id).delete();
  }
}
