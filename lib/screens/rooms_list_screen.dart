import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsListScreen extends StatelessWidget {
  const RoomsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Salas e Laboratórios')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhuma sala cadastrada.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final nome = data['nome'] ?? 'Sem nome';
              final tipo = data['tipo'] ?? 'sala';
              final capacidade = data['capacidade'] ?? 0;
              final disponivel = data['disponivel'] ?? true;
              if (!disponivel) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.all(8),
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                child: ListTile(
                  title: Text(
                    nome,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  subtitle: Text(
                    'Tipo: $tipo | Capacidade: $capacidade',
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDarkMode ? Colors.white70 : Colors.grey,
                  ),
                  onTap: () => Navigator.pushNamed(context, '/schedule', arguments: docs[index].id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}