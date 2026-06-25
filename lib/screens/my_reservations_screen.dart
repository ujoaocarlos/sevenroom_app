import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../services/auth_services.dart';
import '../services/reservation_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/reservation_card.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {

  Future<void> _cancelReservation(String docId) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reservationRepository = Provider.of<ReservationRepository>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar reserva', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza que deseja cancelar esta reserva?', style: TextStyle(fontFamily: 'Montserrat')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Não', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF9E99B5) : AppTheme.neutral700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sim, cancelar', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await reservationRepository.cancel(docId);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Reserva cancelada'), backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUserId;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final subtitleColor = isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral400;

    if (userId == null) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
        appBar: AppBar(
          title: const Text('Minhas Reservas'),
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: subtitleColor),
              const SizedBox(height: 16),
              Text(
                'Faça login para ver suas reservas',
                style: TextStyle(fontFamily: 'Montserrat', color: subtitleColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: Provider.of<ReservationRepository>(context, listen: false)
            .userReservationsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar reservas', style: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(fontFamily: 'Montserrat', color: subtitleColor)),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reservations = snapshot.data?.where((reservation) => reservation.status != 'cancelado').toList() ?? [];
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: subtitleColor),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma reserva encontrada',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, color: subtitleColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return ReservationCard(
                reservation: reservation,
                showCancel: reservation.status != 'cancelado',
                onCancel: reservation.id != null ? () => _cancelReservation(reservation.id!) : null,
              );
            },
          );
        },
      ),
    );
  }
}