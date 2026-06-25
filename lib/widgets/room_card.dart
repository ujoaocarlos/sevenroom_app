import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onReserve;

  const RoomCard({super.key, required this.room, this.onTap, this.onReserve});

  IconData _iconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('laboratorio') || t.contains('laboratório')) return Icons.computer_outlined;
    if (t.contains('evento')) return Icons.event_outlined;
    if (t.contains('reuniao') || t.contains('reunião')) return Icons.groups_outlined;
    if (t.contains('convivencia') || t.contains('convivência')) return Icons.chair_outlined;
    return Icons.meeting_room_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = room.disponivel;
    final cardColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppTheme.neutral200;
    final textColor = isDark ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final subtitleColor = isDark ? const Color(0xFF9E99B5) : AppTheme.neutral400;
    final primary = isDark ? AppColors.skyBlue : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_iconForType(room.tipo), color: primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  // Name + Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room.nome,
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor)),
                        const SizedBox(height: 2),
                        Text(_capitalize(room.tipo.replaceAll('_', ' ')),
                            style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isAvailable ? AppColors.success : AppColors.error)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isAvailable ? 'Disponível' : 'Indisponível',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isAvailable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 16),

              // Meta information and Reserve Button
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _meta(Icons.location_on_outlined, room.local, subtitleColor),
                      _meta(Icons.people_outline_rounded,
                          '${room.capacidade} pessoas', subtitleColor),
                    ],
                  ),
                  // Reserve Button
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: isAvailable ? onReserve : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAvailable ? primary : (isDark ? AppColors.darkBorder : AppTheme.neutral200),
                        foregroundColor:
                            isAvailable ? Colors.white : (isDark ? const Color(0xFF6B6680) : AppTheme.neutral400),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        elevation: 0,
                        textStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                      child: Text(isAvailable ? 'Reservar' : 'Ocupado'),
                    ),
                  ),
                ],
              ),

              // Flags / Special conditions
              if (room.bloquearNoturno || room.exigeAutorizacaoFimSemana || room.exigeAutorizacaoSempre) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (room.bloquearNoturno)
                      _flag('Sem acesso noturno', Icons.nights_stay_outlined, subtitleColor, isDark ? AppColors.darkBorder : AppTheme.neutral100),
                    if (room.exigeAutorizacaoSempre)
                      _flag('Exige autorização', Icons.verified_user_outlined, AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
                    if (room.exigeAutorizacaoFimSemana && !room.exigeAutorizacaoSempre)
                      _flag('Auth. fim de semana', Icons.weekend_outlined, subtitleColor, isDark ? AppColors.darkBorder : AppTheme.neutral100),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _flag(String label, IconData icon, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color)),
      ]),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
