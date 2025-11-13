import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/editing_object.dart';

/// Provider per la lista di tutti gli oggetti di editing
final editingObjectsProvider = StateProvider<List<EditingObject>>((ref) => []);

/// Provider per l'oggetto attualmente in creazione (mentre si disegna)
final currentEditingObjectProvider = StateProvider<EditingObject?>((ref) => null);

/// Provider per l'oggetto selezionato
final selectedObjectIdProvider = StateProvider<String?>((ref) => null);

/// Provider per l'offset di trascinamento
final dragOffsetProvider = StateProvider<Offset?>((ref) => null);

/// Provider per tracking se si sta attivamente disegnando
final isActivelyDrawingProvider = StateProvider<bool>((ref) => false);

/// Provider computed per ottenere l'oggetto selezionato
final selectedObjectProvider = Provider<EditingObject?>((ref) {
  final selectedId = ref.watch(selectedObjectIdProvider);
  if (selectedId == null) return null;

  final objects = ref.watch(editingObjectsProvider);
  try {
    return objects.firstWhere((obj) => obj.id == selectedId);
  } catch (e) {
    return null;
  }
});
