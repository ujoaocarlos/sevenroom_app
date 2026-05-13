import 'package:flutter/material.dart';
import 'rooms_list_screen.dart';
import 'my_reservations_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('7Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomsListScreen(),
                  ),
                );
              },
              child: const Text('Reservar Sala'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyReservationsScreen(),
                  ),
                );
              },
              child: const Text('Minhas Reservas'),
            ),
          ],
        ),
      ),
    );
  }
}