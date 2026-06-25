import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../services/auth_services.dart';
import '../services/email_service.dart';
import '../services/reservation_repository.dart';
import '../services/room_repository.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/reservation_card.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();
  late final RoomRepository _roomRepository;
  late final ReservationRepository _reservationRepository;
  late final EmailService _emailService;
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _roomRepository = context.read<RoomRepository>();
    _reservationRepository = context.read<ReservationRepository>();
    _emailService = context.read<EmailService>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _checkAdmin();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _auth.isAdmin();
    if (!mounted) {
      return;
    }
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Acesso negado. Você não é administrador.'),
            backgroundColor: AppColors.error),
      );
      Navigator.pop(context);
      return;
    }
    setState(() {
      _isAdmin = true;
      _isLoading = false;
    });
  }

  Future<void> _updateReservationStatus(
    Reservation reservation,
    String newStatus,
  ) async {
    try {
      final previousStatus = reservation.status;
      final reservationId = reservation.id;
      if (reservationId == null || reservationId.isEmpty) {
        throw Exception('Reserva sem identificador.');
      }

      await _reservationRepository.updateStatus(reservationId, newStatus);
      if (newStatus == 'aprovado' && previousStatus != 'aprovado') {
        final approvedReservation = Reservation(
          id: reservation.id,
          roomId: reservation.roomId,
          roomDocId: reservation.roomDocId,
          userId: reservation.userId,
          responsavelNome: reservation.responsavelNome,
          status: newStatus,
          data: reservation.data,
          horaInicio: reservation.horaInicio,
          horaFim: reservation.horaFim,
          createdAt: reservation.createdAt,
          email: reservation.email,
        );
        _emailService
            .sendReservationApprovedEmail(approvedReservation)
            .catchError((error) {
          debugPrint('Erro ao enviar e-mail de aprovação: $error');
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva ${_statusText(newStatus)}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'aprovado':
        return 'aprovada';
      case 'recusado':
        return 'recusada';
      case 'cancelado':
        return 'cancelada';
      default:
        return status;
    }
  }

  Future<void> _addOrUpdateRoom(
      {String? docId, Map<String, dynamic>? existingData}) async {
    final isEditing = docId != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final nomeController =
        TextEditingController(text: existingData?['nome'] ?? '');
    final tipoController =
        TextEditingController(text: existingData?['tipo'] ?? 'sala_aula');
    final localController =
        TextEditingController(text: existingData?['local'] ?? '');
    final capacidadeController = TextEditingController(
        text: (existingData?['capacidade'] ?? 50).toString());
    final taxaController = TextEditingController(
        text: (existingData?['taxaPorTurno'] ?? 0.0).toString());
    bool disponivel = existingData?['disponivel'] ?? true;
    bool bloquearNoturno = existingData?['bloquearNoturno'] ?? false;
    bool exigeAutorizacaoFimSemana =
        existingData?['exigeAutorizacaoFimSemana'] ?? false;
    bool exigeAutorizacaoSempre =
        existingData?['exigeAutorizacaoSempre'] ?? false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEditing ? 'Editar Sala' : 'Nova Sala',
            style: const TextStyle(
                fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nomeController,
                      decoration:
                          const InputDecoration(labelText: 'Nome da sala'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tipoController,
                      decoration: const InputDecoration(
                          labelText:
                              'Tipo (sala_aula, laboratorio, evento, etc.)'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: localController,
                      decoration:
                          const InputDecoration(labelText: 'Localização'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: capacidadeController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Capacidade'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: taxaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Taxa por turno (R\$)'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Disponível',
                          style: TextStyle(
                              fontFamily: 'Montserrat', fontSize: 14)),
                      value: disponivel,
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                  ? AppColors.skyBlue
                                  : AppColors.primaryBlue)
                              : null),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                      ? AppColors.skyBlue
                                      : AppColors.primaryBlue)
                                  .withAlpha(120)
                              : null),
                      onChanged: (val) =>
                          setStateDialog(() => disponivel = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bloquear noturno (22h às 6h)',
                          style: TextStyle(
                              fontFamily: 'Montserrat', fontSize: 14)),
                      value: bloquearNoturno,
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                  ? AppColors.skyBlue
                                  : AppColors.primaryBlue)
                              : null),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                      ? AppColors.skyBlue
                                      : AppColors.primaryBlue)
                                  .withAlpha(120)
                              : null),
                      onChanged: (val) =>
                          setStateDialog(() => bloquearNoturno = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auth nos fins de semana',
                          style: TextStyle(
                              fontFamily: 'Montserrat', fontSize: 14)),
                      value: exigeAutorizacaoFimSemana,
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                  ? AppColors.skyBlue
                                  : AppColors.primaryBlue)
                              : null),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                      ? AppColors.skyBlue
                                      : AppColors.primaryBlue)
                                  .withAlpha(120)
                              : null),
                      onChanged: (val) =>
                          setStateDialog(() => exigeAutorizacaoFimSemana = val),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Exige autorização sempre',
                          style: TextStyle(
                              fontFamily: 'Montserrat', fontSize: 14)),
                      value: exigeAutorizacaoSempre,
                      thumbColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                  ? AppColors.skyBlue
                                  : AppColors.primaryBlue)
                              : null),
                      trackColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? (isDark
                                      ? AppColors.skyBlue
                                      : AppColors.primaryBlue)
                                  .withAlpha(120)
                              : null),
                      onChanged: (val) =>
                          setStateDialog(() => exigeAutorizacaoSempre = val),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: isDark
                          ? const Color(0xFF9E99B5)
                          : AppTheme.neutral700))),
          ElevatedButton(
            onPressed: () async {
              final stateNavigator = Navigator.of(this.context);
              final stateMessenger = ScaffoldMessenger.of(this.context);
              if (formKey.currentState!.validate()) {
                final room = Room(
                  id: docId,
                  nome: nomeController.text.trim(),
                  tipo: tipoController.text.trim(),
                  local: localController.text.trim(),
                  capacidade: int.parse(capacidadeController.text),
                  taxaPorTurno: double.parse(taxaController.text),
                  disponivel: disponivel,
                  bloquearNoturno: bloquearNoturno,
                  exigeAutorizacaoFimSemana: exigeAutorizacaoFimSemana,
                  exigeAutorizacaoSempre: exigeAutorizacaoSempre,
                );
                try {
                  if (isEditing) {
                    await _roomRepository.update(room);
                  } else {
                    await _roomRepository.add(room);
                  }
                  stateNavigator.pop();
                  stateMessenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            isEditing ? 'Sala atualizada!' : 'Sala criada!'),
                        backgroundColor: AppColors.success),
                  );
                } catch (e) {
                  stateMessenger.showSnackBar(
                    SnackBar(
                        content: Text('Erro: $e'),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? AppColors.skyBlue : AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isEditing ? 'Atualizar' : 'Criar',
                style: const TextStyle(
                    fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(String docId, String nome) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stateMessenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar exclusão',
            style: TextStyle(
                fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja excluir a sala "$nome"?',
            style: const TextStyle(fontFamily: 'Montserrat')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar',
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: isDark
                          ? const Color(0xFF9E99B5)
                          : AppTheme.neutral700))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Excluir',
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _roomRepository.delete(docId);
        stateMessenger.showSnackBar(
          SnackBar(
              content: Text('Sala "$nome" excluída'),
              backgroundColor: AppColors.warning),
        );
      } catch (e) {
        stateMessenger.showSnackBar(
          SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Widget _buildReservationsList({String? statusFilter}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral400;

    return StreamBuilder<List<Reservation>>(
      stream: _reservationRepository.allReservationsStream(
          statusFilter: statusFilter),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Erro: ${snapshot.error}',
                  style: const TextStyle(fontFamily: 'Montserrat')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reservations = snapshot.data ?? [];
        if (reservations.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma reserva encontrada',
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: subtitleColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: reservations.length,
          itemBuilder: (context, index) {
            final reservation = reservations[index];
            final reservationId = reservation.id ?? '';
            final status = reservation.status;

            return ReservationCard(
              reservation: reservation,
              actions: [
                if (status == 'pendente' ||
                    status == 'pendente_autorizacao') ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        _updateReservationStatus(reservation, 'aprovado'),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 18, color: AppColors.success),
                    label: const Text('Aprovar',
                        style: TextStyle(color: AppColors.success)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _updateReservationStatus(reservation, 'recusado'),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 18, color: AppColors.error),
                    label: const Text('Recusar',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: isDarkMode
                          ? const Color(0xFF9E99B5)
                          : AppTheme.neutral700),
                  onPressed: () async {
                    final stateMessenger = ScaffoldMessenger.of(this.context);
                    try {
                      await _reservationRepository.delete(reservationId);
                      stateMessenger.showSnackBar(
                        const SnackBar(
                            content: Text('Reserva deletada'),
                            backgroundColor: AppColors.error),
                      );
                    } catch (e) {
                      stateMessenger.showSnackBar(
                        SnackBar(
                            content: Text('Erro: $e'),
                            backgroundColor: AppColors.error),
                      );
                    }
                  },
                  tooltip: 'Deletar reserva',
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoomsManagement() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor =
        isDarkMode ? const Color(0xFF9E99B5) : AppTheme.neutral400;
    final cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final borderColor = isDarkMode ? AppColors.darkBorder : AppTheme.neutral200;
    final textColor =
        isDarkMode ? const Color(0xFFE2E0EC) : AppTheme.neutral900;
    final primary = isDarkMode ? AppColors.skyBlue : AppTheme.primaryColor;

    return StreamBuilder<List<Room>>(
      stream: _roomRepository.roomsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text('Erro: ${snapshot.error}',
                  style: const TextStyle(fontFamily: 'Montserrat')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.meeting_room, size: 64, color: subtitleColor),
                const SizedBox(height: 16),
                Text('Nenhuma sala cadastrada',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        color: subtitleColor)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addOrUpdateRoom,
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar sala'),
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
            final roomId = room.id ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(room.nome,
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        color: textColor)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'Tipo: ${room.tipo} | Capacidade: ${room.capacidade} | ${room.disponivel ? "Disponível" : "Indisponível"}',
                      style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: primary),
                      onPressed: () => _addOrUpdateRoom(
                          docId: roomId, existingData: room.toMap()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      onPressed: () => _deleteRoom(roomId, room.nome),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primary = isDarkMode ? AppColors.skyBlue : AppTheme.primaryColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
        body: const Center(
          child: Text('Verificando permissões...',
              style: TextStyle(fontFamily: 'Montserrat')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppTheme.neutral50,
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        backgroundColor:
            isDarkMode ? AppColors.darkSurface : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
              fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Montserrat'),
          tabs: const [
            Tab(text: 'Todas Reservas', icon: Icon(Icons.list_alt)),
            Tab(text: 'Salas', icon: Icon(Icons.meeting_room)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addOrUpdateRoom,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Somente administradores podem aprovar, recusar ou excluir reservas de qualquer usuário.',
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: isDarkMode
                            ? const Color(0xFFE2E0EC)
                            : AppTheme.neutral900,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReservationsList(statusFilter: null),
                _buildRoomsManagement(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
