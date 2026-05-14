import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'finance_provider.dart';
import 'reviews_provider.dart';
import 'wishlist_provider.dart';
import 'cinema_notes_provider.dart';

/// Provider che carica tutti i dati locali all'avvio
/// Usare: await ref.read(initializeAppProvider.future);
final initializeAppProvider = FutureProvider((ref) async {
  // Carica i dati in parallelo
  final futures = <Future<void>>[
    ref.read(financeProvider.notifier).loadFromDisk(),
    ref.read(reviewsProvider.notifier).loadFromDisk(),
    ref.read(wishlistProvider.notifier).loadFromDisk(),
    ref.read(cinemaNotesProvider.notifier).loadFromDisk(),
  ];
  
  await Future.wait<void>(futures);

  return true;
});
