import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onCancel;
  final bool showCancel;
  final List<Widget>? actions;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCancel,
    this.showCancel = false,
    this.actions,
  });

  Color get statusColor {
    switch (reservation.status) {
      case 'aprovado':
        return AppColors.success;
      case 'recusado':
        return AppColors.error;
      case 'pendente':
        return AppColors.warning;
      case 'pendente_autorizacao':
        return const Color(0xFF7C4FE0); // 7me violet
      case 'cancelado':
        return Colors.grey;
      default:
        return AppColors.primaryBlue;
    }
  }

  String get statusLabel => reservation.status.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorder : AppTheme.neutral200;
    final textColor = isDarkMode ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final subtitleColor = isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral700;
    final primary = isDarkMode ? AppColors.skyBlue : AppTheme.primaryColor;

    final inicio = reservation.horaInicio;
    final fim = reservation.horaFim;
    final dateLabel = reservation.data != null
        ? DateFormat('dd/MM/yyyy').format(reservation.data!)
        : 'Data não informada';
    final timeLabel = (inicio != null && fim != null)
        ? '${DateFormat('HH:mm').format(inicio)} - ${DateFormat('HH:mm').format(fim)}'
        : 'Horário não disponível';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.meeting_room, size: 28, color: primary),
                ),
                const SizedBox(width: 16),
                // Reservation details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.roomId,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dateLabel, style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500)),
                      Text(timeLabel, style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),
            Text('Responsável: ${reservation.responsavelNome}',
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500)),
            if (reservation.email != null)
              Text(reservation.email!, style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500)),
            if ((actions?.isNotEmpty ?? false) || (showCancel && onCancel != null)) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (actions != null) ...actions!,
                  if (showCancel && onCancel != null)
                    ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancelar reserva', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
