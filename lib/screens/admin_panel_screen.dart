import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Salas', icon: Icon(Icons.meeting_room)),
            Tab(text: 'Reservas pendentes', icon: Icon(Icons.pending_actions)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RoomsManagementTab(),
          _PendingReservationsTab(),
        ],
      ),
    );
  }
}

// ---------- Aba: Gerenciamento de Salas ----------
class _RoomsManagementTab extends StatefulWidget {
  @override
  State<_RoomsManagementTab> createState() => _RoomsManagementTabState();
}

class _RoomsManagementTabState extends State<_RoomsManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _capacidadeController = TextEditingController();
  final _tipoController = TextEditingController();
  final _taxaController = TextEditingController();
  String? _editDocId;

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'nome': _nomeController.text.trim(),
      'capacidade': int.tryParse(_capacidadeController.text) ?? 0,
      'tipo': _tipoController.text.trim(),
      'taxaPorTurno': double.tryParse(_taxaController.text) ?? 0.0,
      'disponivel': true,
      'bloquearNoturno': _tipoController.text == 'sala_aula',
      'exigeAutorizacaoFimSemana': _tipoController.text == 'laboratorio' || _tipoController.text == 'convivencia',
      'exigeAutorizacaoSempre': _tipoController.text == 'convivencia' || _tipoController.text == 'reuniao',
    };
    final db = FirebaseFirestore.instance;
    if (_editDocId == null) {
      await db.collection('rooms').add(data);
    } else {
      await db.collection('rooms').doc(_editDocId).update(data);
    }
    _clearForm();
  }

  void _editRoom(String id, Map<String, dynamic> data) {
    _editDocId = id;
    _nomeController.text = data['nome'] ?? '';
    _capacidadeController.text = data['capacidade'].toString();
    _tipoController.text = data['tipo'] ?? '';
    _taxaController.text = data['taxaPorTurno'].toString();
  }

  void _deleteRoom(String id) async {
    await FirebaseFirestore.instance.collection('rooms').doc(id).delete();
  }

  void _clearForm() {
    _editDocId = null;
    _nomeController.clear();
    _capacidadeController.clear();
    _tipoController.clear();
    _taxaController.clear();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome da sala'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _capacidadeController,
                      decoration: const InputDecoration(labelText: 'Capacidade'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _tipoController,
                      decoration: const InputDecoration(labelText: 'Tipo (sala_aula, laboratorio, evento, convivencia, reuniao)'),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    TextFormField(
                      controller: _taxaController,
                      decoration: const InputDecoration(labelText: 'Taxa por turno (R\$)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _saveRoom,
                          child: Text(_editDocId == null ? 'Adicionar' : 'Atualizar'),
                        ),
                        if (_editDocId != null)
                          TextButton(
                            onPressed: _clearForm,
                            child: const Text('Cancelar'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['nome'] ?? ''),
                    subtitle: Text(
                      'Tipo: ${data['tipo']} | Capacidade: ${data['capacidade']} | Taxa: R\$${data['taxaPorTurno']}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editRoom(docs[index].id, data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRoom(docs[index].id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------- Aba: Reservas Pendentes ----------
class _PendingReservationsTab extends StatelessWidget {
  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('reservations').doc(docId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where('status', whereIn: ['pendente', 'pendente_autorizacao'])
          .orderBy('data', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Nenhuma reserva pendente.'));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final inicio = (data['horaInicio'] as Timestamp).toDate();
            final fim = (data['horaFim'] as Timestamp).toDate();
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Sala: ${data['roomId']} | Usuário: ${data['userId']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(inicio)} - ${DateFormat('HH:mm').format(fim)}',
                    ),
                    Text('Status: ${data['status']}'),
                    Text('Responsável: ${data['responsavelNome']}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _updateStatus(docs[index].id, 'aprovado'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _updateStatus(docs[index].id, 'recusado'),
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
}