import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../services/auth_services.dart';
import '../services/email_service.dart';
import '../services/room_repository.dart';
import '../services/reservation_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class ScheduleScreen extends StatefulWidget {
  final String roomDocId;
  final String? roomName;

  const ScheduleScreen({super.key, required this.roomDocId, this.roomName});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ReservationRepository _reservationRepository;
  late final RoomRepository _roomRepository;
  late final AuthService _authService;
  late final EmailService _emailService;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  String? _roomName;
  Room? _room;
  int _selectedDurationMinutes = 60;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmReservation() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Faça login para reservar esta sala.'),
              behavior: SnackBarBehavior.floating),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    if (_room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Dados da sala ainda não foram carregados.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final endDateTime =
          startDateTime.add(Duration(minutes: _selectedDurationMinutes));

      // 1. Validar contra bloqueio noturno
      final bookingDay =
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
      final nightEndMorning = bookingDay.add(const Duration(hours: 6));
      final nightStartEvening = bookingDay.add(const Duration(hours: 22));

      if (_room!.bloquearNoturno) {
        if (startDateTime.isBefore(nightEndMorning) ||
            endDateTime.isAfter(nightStartEvening)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Esta sala não pode ser reservada no período noturno (22h às 06h).'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // 2. Validar conflito de agendamento (Double booking)
      final activeReservations = await _reservationRepository
          .getActiveReservationsForRoomAndDate(widget.roomDocId, _selectedDate);
      final hasConflict = activeReservations.any((existing) {
        return existing.horaInicio != null &&
            existing.horaFim != null &&
            existing.horaInicio!.isBefore(endDateTime) &&
            existing.horaFim!.isAfter(startDateTime);
      });

      if (hasConflict) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Esta sala já está reservada para o horário selecionado.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 3. Determinar o status da reserva
      final isWeekend = startDateTime.weekday == DateTime.saturday ||
          startDateTime.weekday == DateTime.sunday;
      final requiresApproval = _room!.exigeAutorizacaoSempre ||
          (_room!.exigeAutorizacaoFimSemana && isWeekend);
      final initialStatus = requiresApproval ? 'pendente' : 'aprovado';

      final reservation = Reservation(
        roomId: _roomName ?? widget.roomDocId,
        roomDocId: widget.roomDocId,
        userId: user.uid,
        responsavelNome:
            user.displayName ?? user.email?.split('@').first ?? 'Usuário',
        status: initialStatus,
        data: bookingDay,
        horaInicio: startDateTime,
        horaFim: endDateTime,
        email: user.email,
      );

      final savedReservation = await _reservationRepository.addIfNoConflict(
        reservation,
      );
      _emailService.sendReservationCreatedEmail(savedReservation).catchError((
        error,
      ) {
        debugPrint('Erro ao enviar e-mail de reserva: $error');
      });
      if (mounted) {
        final statusMsg = initialStatus == 'aprovado'
            ? 'criada e confirmada com sucesso!'
            : 'solicitada com sucesso! Aguarde a aprovação do administrador.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Reserva para ${_roomName ?? widget.roomDocId} $statusMsg'),
              behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } on ReservationConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao reservar: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _reservationRepository = context.read<ReservationRepository>();
    _roomRepository = context.read<RoomRepository>();
    _authService = context.read<AuthService>();
    _emailService = context.read<EmailService>();
    _roomName = widget.roomName;
    _loadRoomDetails();
  }

  Future<void> _loadRoomDetails() async {
    try {
      final room = await _roomRepository.getById(widget.roomDocId);
      if (room != null) {
        setState(() {
          _room = room;
          _roomName = room.nome;
        });
      }
    } catch (_) {}
  }

  Widget _durationChip(
      int minutes, String label, Color primary, bool isDarkMode) {
    final isSelected = _selectedDurationMinutes == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primary,
      backgroundColor: isDarkMode ? AppColors.darkBorder : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontFamily: 'Montserrat',
        color: isSelected
            ? Colors.white
            : (isDarkMode ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedDurationMinutes = minutes);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dateLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final timeLabel = _selectedTime.format(context);
    final cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorder : AppTheme.neutral200;
    final textColor =
        isDarkMode ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final subtitleColor =
        isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral700;
    final primary = isDarkMode ? AppColors.skyBlue : AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Agendar Sala'),
        backgroundColor:
            isDarkMode ? AppColors.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_roomName ?? widget.roomDocId,
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 8),
            if (_room != null) ...[
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: subtitleColor),
                      const SizedBox(width: 4),
                      Text(_room!.local,
                          style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: subtitleColor,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 16, color: subtitleColor),
                      const SizedBox(width: 4),
                      Text('Capacidade: ${_room!.capacidade} pessoas',
                          style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: subtitleColor,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text('Sala selecionada: ${_roomName ?? widget.roomDocId}',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: subtitleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Data da reserva',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(dateLabel,
                        style: const TextStyle(fontFamily: 'Montserrat')),
                    trailing: Icon(Icons.calendar_today, color: primary),
                    onTap: _pickDate,
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    title: const Text('Horário de início',
                        style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(timeLabel,
                        style: const TextStyle(fontFamily: 'Montserrat')),
                    trailing: Icon(Icons.access_time, color: primary),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Duração da Reserva',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _durationChip(30, '30 min', primary, isDarkMode),
                _durationChip(60, '1 hora', primary, isDarkMode),
                _durationChip(120, '2 horas', primary, isDarkMode),
                _durationChip(180, '3 horas', primary, isDarkMode),
              ],
            ),
            const SizedBox(height: 28),
            Text('Reservas para este dia',
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 12),
            FutureBuilder<List<Reservation>>(
              future:
                  _reservationRepository.getActiveReservationsForRoomAndDate(
                      widget.roomDocId, _selectedDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(
                      'Erro ao carregar reservas existentes: ${snapshot.error}',
                      style: const TextStyle(
                          fontFamily: 'Montserrat', color: Colors.red));
                }
                final reservations = snapshot.data ?? [];
                if (reservations.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text('Nenhuma reserva para este dia. Sala livre!',
                          style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: subtitleColor,
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                }

                // Sort reservations by time
                reservations.sort((a, b) => (a.horaInicio ?? DateTime.now())
                    .compareTo(b.horaInicio ?? DateTime.now()));

                return Column(
                  children: reservations.map((res) {
                    final startStr = res.horaInicio != null
                        ? DateFormat('HH:mm').format(res.horaInicio!)
                        : '--:--';
                    final endStr = res.horaFim != null
                        ? DateFormat('HH:mm').format(res.horaFim!)
                        : '--:--';
                    final isAprovado = res.status == 'aprovado';
                    final resColor =
                        isAprovado ? AppColors.success : AppColors.warning;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.history_toggle_off, color: primary),
                        title: Text('$startStr - $endStr',
                            style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('Responsável: ${res.responsavelNome}',
                            style: const TextStyle(fontFamily: 'Montserrat')),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: resColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            res.status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: resColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar reserva'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
