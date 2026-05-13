import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> seedRooms() async {
  await Firebase.initializeApp();
  final roomsRef = FirebaseFirestore.instance.collection('rooms');

  // Salas numeradas
  final salasNumeros = [111,112,113,114,115,116,117,118,119,120,201,202,203,211,212,213,214,215,216];
  for (var num in salasNumeros) {
    await roomsRef.doc('sala_$num').set({
      'nome': 'Sala $num',
      'tipo': 'sala_aula',
      'capacidade': 50,
      'recursos': [],
      'disponivel': true,
      'bloquearNoturno': true,
      'exigeAutorizacaoFimSemana': false,
      'exigeAutorizacaoSempre': false,
      'taxaPorTurno': num <= 120 ? 66.0 : 99.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Laboratórios
  final labs = {
    'lab_1': 'Laboratório 1: Simulações Hospitalares',
    'lab_2': 'Laboratório 2: Técnica Dietética, Bebidas e Análise Sensorial',
    'lab_3': 'Laboratório 3: Modelos Anatômicos',
    'lab_4': 'Laboratório 4: Anatomia',
    'lab_6': 'Laboratório 6: Patologia',
    'lab_7': 'Laboratório 7: Histologia e Embriologia',
    'lab_8': 'Laboratório 8: Bromatologia, Biologia e Genética',
    'lab_9': 'Laboratório 9: Bioquímica e Fisiologia',
    'lab_10': 'Laboratório 10: Ortese e Prótese',
    'lab_11': 'Laboratório 11: Avaliação Física',
    'lab_12': 'Laboratório 12: Radiologia',
    'lab_13': 'Laboratório 13: Odontológico com Simuladores',
    'lab_14': 'Laboratório 14: Odontológico',
    'lab_15': 'Laboratório 15: Habilidades Terapêuticas',
    'lab_16': 'Laboratório 16: Atividades Sensorias',
  };
  for (var entry in labs.entries) {
    await roomsRef.doc(entry.key).set({
      'nome': entry.value,
      'tipo': 'laboratorio',
      'capacidade': 20,
      'recursos': [],
      'disponivel': true,
      'bloquearNoturno': true,
      'exigeAutorizacaoFimSemana': true,
      'exigeAutorizacaoSempre': false,
      'taxaPorTurno': 300.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sala show
  await roomsRef.doc('sala_show').set({
    'nome': 'Sala Show',
    'tipo': 'evento',
    'capacidade': 100,
    'recursos': ['palco', 'som'],
    'disponivel': true,
    'bloquearNoturno': false,
    'exigeAutorizacaoFimSemana': true,
    'exigeAutorizacaoSempre': false,
    'taxaPorTurno': 0.0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Centro de convivência
  await roomsRef.doc('centro_convivencia').set({
    'nome': 'Centro de Convivência',
    'tipo': 'convivencia',
    'capacidade': 150,
    'recursos': ['mesas', 'cadeiras'],
    'disponivel': true,
    'bloquearNoturno': false,
    'exigeAutorizacaoFimSemana': true,
    'exigeAutorizacaoSempre': true,
    'taxaPorTurno': 330.0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Sala de reunião professores
  await roomsRef.doc('sala_reuniao_professores').set({
    'nome': 'Sala de Reunião dos Professores',
    'tipo': 'reuniao',
    'capacidade': 20,
    'recursos': ['mesa redonda', 'projetor'],
    'disponivel': true,
    'bloquearNoturno': false,
    'exigeAutorizacaoFimSemana': true,
    'exigeAutorizacaoSempre': true,
    'taxaPorTurno': 0.0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  print('✅ Salas e laboratórios cadastrados com sucesso!');
}