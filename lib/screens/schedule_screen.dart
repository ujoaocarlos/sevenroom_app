import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  final String roomId;
  const ScheduleScreen({super.key, required this.roomId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeResponsavelController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _materialController = TextEditingController();
  final _atividadeController = TextEditingController();
  final _turmaController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _observacoesController = TextEditingController();

  DateTime? _dataSelecionada;
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  bool _usoExterno = false;
  double _taxa = 0.0;
  bool _isLoading = false;
  Map<String, dynamic>? _roomData;

  @override
  void initState() {
    super.initState();
    _loadRoomData();
  }

  Future<void> _loadRoomData() async {
    final doc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
    if (doc.exists) setState(() => _roomData = doc.data());
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 2)),
      firstDate: DateTime.now().add(const Duration(days: 2)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _dataSelecionada = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? TimeOfDay.now() : (_horaInicio ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _horaInicio = picked;
        else _horaFim = picked;
      });
    }
  }

  void _calcularTaxa() {
    if (_usoExterno && _roomData != null) {
      setState(() => _taxa = (_roomData!['taxaPorTurno'] ?? 0.0).toDouble());
    } else {
      setState(() => _taxa = 0.0);
    }
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataSelecionada == null || _horaInicio == null || _horaFim == null) {
      _showError('Preencha data e horários');
      return;
    }

    final inicio = DateTime(
      _dataSelecionada!.year, _dataSelecionada!.month, _dataSelecionada!.day,
      _horaInicio!.hour, _horaInicio!.minute,
    );
    final fim = DateTime(
      _dataSelecionada!.year, _dataSelecionada!.month, _dataSelecionada!.day,
      _horaFim!.hour, _horaFim!.minute,
    );

    final duracao = fim.difference(inicio).inMinutes;
    if (duracao < 30) { _showError('A reserva deve ter no mínimo 30 minutos.'); return; }
    if (duracao > 240) { _showError('A reserva pode ter no máximo 4 horas (1 turno).'); return; }

    final hoje = DateTime.now();
    final limite = DateTime(hoje.year, hoje.month, hoje.day).add(const Duration(days: 2));
    if (inicio.isBefore(limite)) { _showError('A reserva deve ser feita com pelo menos 48 horas de antecedência.'); return; }

    if (_roomData?['bloquearNoturno'] == true) {
      final horaInicioNum = _horaInicio!.hour + _horaInicio!.minute / 60.0;
      if (horaInicioNum >= 22 || horaInicioNum < 6) {
        _showError('Esta sala não pode ser reservada no período noturno (22h às 6h).');
        return;
      }
    }

    setState(() => _isLoading = true);
    final db = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { _showError('Usuário não autenticado.'); setState(() => _isLoading = false); return; }

    try {
      final query = await db.collection('reservations')
          .where('roomId', isEqualTo: widget.roomId)
          .where('status', isEqualTo: 'ativa')
          .get();

      bool conflito = false;
      for (var doc in query.docs) {
        final data = doc.data();
        final resInicio = (data['horaInicio'] as Timestamp).toDate();
        final resFim = (data['horaFim'] as Timestamp).toDate();
        if (inicio.isBefore(resFim) && fim.isAfter(resInicio)) {
          conflito = true;
          break;
        }
      }
      if (conflito) throw Exception('Horário já reservado para esta sala.');

      String status = 'pendente';
      if (_roomData?['exigeAutorizacaoSempre'] == true) status = 'pendente_autorizacao';
      if (_roomData?['exigeAutorizacaoFimSemana'] == true && _isWeekend(_dataSelecionada!)) status = 'pendente_autorizacao';

      final reservationData = {
        'roomId': widget.roomId,
        'userId': user.uid,
        'status': status,
        'data': Timestamp.fromDate(_dataSelecionada!),
        'horaInicio': Timestamp.fromDate(inicio),
        'horaFim': Timestamp.fromDate(fim),
        'responsavelNome': _nomeResponsavelController.text.trim(),
        'responsavelTelefone': _telefoneController.text.trim(),
        'materialSolicitado': _materialController.text.trim(),
        'atividade': _atividadeController.text.trim(),
        'turmaInstituicao': _turmaController.text.trim(),
        'quantidadePessoas': int.tryParse(_quantidadeController.text) ?? 1,
        'observacoes': _observacoesController.text.trim(),
        'usoExterno': _usoExterno,
        'taxaAplicada': _taxa,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await db.collection('reservations').add(reservationData);

      _showSuccess('Reserva solicitada com sucesso! Aguarde aprovação.');
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (_roomData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: Text('Agendar ${_roomData!['nome']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nomeResponsavelController,
                decoration: InputDecoration(
                  labelText: 'Nome do responsável',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _materialController,
                decoration: InputDecoration(
                  labelText: 'Material solicitado (projetor, caixa de som, etc.)',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _atividadeController,
                decoration: InputDecoration(
                  labelText: 'Atividade que será realizada',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _turmaController,
                decoration: InputDecoration(
                  labelText: 'Turma/período/Instituição',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantidadeController,
                decoration: InputDecoration(
                  labelText: 'Quantidade de pessoas',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey[700]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Uso externo?', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                value: _usoExterno,
                onChanged: (val) { setState(() => _usoExterno = val); _calcularTaxa(); },
              ),
              if (_taxa > 0) 
                Text(
                  'Taxa a pagar: R\$${_taxa.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.green[300] : Colors.green[700],
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                child: ListTile(
                  title: Text(
                    _dataSelecionada == null ? 'Selecione a data' : DateFormat('dd/MM/yyyy').format(_dataSelecionada!),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  trailing: Icon(Icons.calendar_today, color: isDarkMode ? Colors.white70 : Colors.grey),
                  onTap: _selectDate,
                ),
              ),
              Card(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                child: ListTile(
                  title: Text(
                    _horaInicio == null ? 'Horário início' : _horaInicio!.format(context),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  trailing: Icon(Icons.access_time, color: isDarkMode ? Colors.white70 : Colors.grey),
                  onTap: () => _selectTime(true),
                ),
              ),
              Card(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                child: ListTile(
                  title: Text(
                    _horaFim == null ? 'Horário fim' : _horaFim!.format(context),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  trailing: Icon(Icons.access_time, color: isDarkMode ? Colors.white70 : Colors.grey),
                  onTap: () => _selectTime(false),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReservation,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Solicitar Reserva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}