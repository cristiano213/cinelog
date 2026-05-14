import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/finance_entry.dart';
import 'local_storage_provider.dart';
import 'cinema_notes_provider.dart';
import 'stats_provider.dart';

// Rimuovi questi import se non servono ad altro nel file, 
// eviterai confusione e dipendenze circolari a livello di file.
// import 'stats_provider.dart'; 
// import 'cinema_notes_provider.dart';

class FinanceLedgerNotifier extends Notifier<List<FinanceLedgerEntry>> {
  @override
  List<FinanceLedgerEntry> build() => [];

  Future<void> loadFromDisk() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    state = await storage.loadFinanceLedger();
  }

  Future<void> addVisione({
    required String movieId,
    required String movieTitle,
    required String cinema,
    required double priceEur,
  }) async {
    final entry = FinanceLedgerEntry(
      id: const Uuid().v4(),
      movieId: movieId,
      movieTitle: movieTitle,
      cinema: cinema,
      priceEur: priceEur,
      dateTime: DateTime.now(),
      count: 1,
    );

    // 1. Aggiorna lo stato
    state = [...state, entry]; 
    
    // 2. Salva (il salvataggio è asincrono ma non blocca la UI)
    await _save();
    
    // ✅ RIMOSSI ref.invalidate! 
    // appStatsProvider si aggiornerà DA SOLO perché fa ref.watch(financeProvider)
  }
  /// Aggiorna un'entrata
  Future<void> updateEntry(String entryId, {
    String? cinema,
    double? priceEur,
  }) async {
    state = state.map((e) {
      if (e.id != entryId) return e;
      return e.copyWith(
        cinema: cinema ?? e.cinema,
        priceEur: priceEur ?? e.priceEur,
      );
    }).toList();
    await _save();

    ref.invalidate(appStatsProvider);
    ref.invalidate(cinemaNotesProvider);
  }

  /// Salva su disk
  Future<void> _save() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.init();
    await storage.saveFinanceLedger(state);
  }
}

final financeProvider = NotifierProvider<FinanceLedgerNotifier, List<FinanceLedgerEntry>>(FinanceLedgerNotifier.new);
