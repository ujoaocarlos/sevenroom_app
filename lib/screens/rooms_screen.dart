import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../services/room_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/room_card.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final subtitleColor = isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral400;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Salas Disponíveis'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Room>>(
        stream: Provider.of<RoomRepository>(context, listen: false).roomsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar salas', style: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(fontFamily: 'Montserrat', color: subtitleColor)),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rooms = snapshot.data!;
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.meeting_room_outlined, size: 80, color: subtitleColor),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma sala cadastrada',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, color: subtitleColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];

              return RoomCard(
                room: room,
                onTap: room.disponivel
                    ? () {
                        Navigator.pushNamed(
                          context,
                          '/schedule',
                          arguments: {'roomDocId': room.id ?? '', 'roomName': room.nome},
                        );
                      }
                    : null,
                onReserve: room.disponivel
                    ? () {
                        Navigator.pushNamed(
                          context,
                          '/schedule',
                          arguments: {'roomDocId': room.id ?? '', 'roomName': room.nome},
                        );
                      }
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}