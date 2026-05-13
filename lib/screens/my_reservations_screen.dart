import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Reservas')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: userId)
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhuma reserva encontrada.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final roomId = data['roomId'] ?? '';
              final status = data['status'] ?? '';
              final inicio = (data['horaInicio'] as Timestamp).toDate();
              final fim = (data['horaFim'] as Timestamp).toDate();
              
              Color statusColor;
              switch (status) {
                case 'aprovado': statusColor = Colors.green; break;
                case 'pendente': statusColor = Colors.orange; break;
                case 'recusado': statusColor = Colors.red; break;
                case 'cancelado': statusColor = Colors.grey; break;
                default: statusColor = Colors.blue;
              }
              
              return Card(
                margin: const EdgeInsets.all(8),
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                child: ListTile(
                  title: Text(
                    'Sala: $roomId',
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('dd/MM/yyyy HH:mm').format(inicio)} - ${DateFormat('HH:mm').format(fim)}',
                        style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 11)),
                        backgroundColor: statusColor.withOpacity(0.2),
                        labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: (status == 'pendente' || status == 'aprovado')
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('reservations')
                                .doc(docs[index].id)
                                .update({'status': 'cancelado'});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reserva cancelada')),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}