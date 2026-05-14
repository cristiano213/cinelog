import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cinema_note.dart';
import 'finance_provider.dart';
import 'local_storage_provider.dart';

class CinemaNotesNotifier extends Notifier<List<CinemaNote>> {
  @override
  List<CinemaNote> build() {
    return [];
  }

  /// Carica le cinema notes da disk
  Future<void> loadFromDisk() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    final notes = await storage.loadCinemaNotes();
    state = notes;
  }

  /// Aggiorna o crea una nota cinema basata sul ledger finanziario
  Future<void> updateCinemaNote(String cinemaName, {String? note}) async {
    final ledger = ref.read(financeProvider);

    // Calcola le statistiche per questo cinema
    final cinemaEntries = ledger.where((e) => e.cinema == cinemaName).toList();
    if (cinemaEntries.isEmpty) return;

    final visitCount = cinemaEntries.length;
    final totalPrice = cinemaEntries.fold<double>(0, (sum, e) => sum + e.totalPrice);
    final avgPrice = totalPrice / visitCount;
    final lastVisit = cinemaEntries.map((e) => e.dateTime).reduce((a, b) => a.isAfter(b) ? a : b);

    final existing = state.firstWhere(
      (n) => n.cinemaName == cinemaName,
      orElse: () => CinemaNote(
        cinemaName: cinemaName,
        note: note ?? '',
        avgPriceEur: avgPrice,
        visitCount: visitCount,
        lastVisit: lastVisit,
      ),
    );

    final updated = existing.copyWith(
      avgPriceEur: avgPrice,
      visitCount: visitCount,
      lastVisit: lastVisit,
      note: note ?? existing.note,
    );

    state = [
      ...state.where((n) => n.cinemaName != cinemaName),
      updated,
    ];

    await _save();
  }

  /// Aggiunge o aggiorna nota testuale per un cinema
  Future<void> setNote(String cinemaName, String note) async {
    final updated = state.firstWhere(
      (n) => n.cinemaName == cinemaName,
      orElse: () => CinemaNote(
        cinemaName: cinemaName,
        note: note,
        avgPriceEur: 0,
        visitCount: 0,
        lastVisit: DateTime.now(),
      ),
    ).copyWith(note: note);

    state = [
      ...state.where((n) => n.cinemaName != cinemaName),
      updated,
    ];

    await _save();
  }

  /// Salva su disk
  Future<void> _save() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    await storage.saveCinemaNotes(state);
  }
}

final cinemaNotesProvider =
    NotifierProvider<CinemaNotesNotifier, List<CinemaNote>>(
  CinemaNotesNotifier.new,
);
