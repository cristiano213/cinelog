import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'finance_provider.dart';
import 'reviews_provider.dart';

/// Statistics calcolate dal finance ledger e reviews
/// Questo è un provider COMPUTED (non ha stato proprio, dipende da altri)
class AppStats {
  final double totalSpent;
  final int totalMoviesSeen;
  final double avgTicketPrice;
  final double avgUserRating;
  final Map<String, int> spendingByMonth; // "2024-05" -> count
  final String? favoriteCinema;

  AppStats({
    required this.totalSpent,
    required this.totalMoviesSeen,
    required this.avgTicketPrice,
    required this.avgUserRating,
    required this.spendingByMonth,
    required this.favoriteCinema,
  });

  String get formattedTotalSpent => '€${totalSpent.toStringAsFixed(2)}';
  String get formattedAvgTicket =>
      '€${avgTicketPrice.toStringAsFixed(2)}';
}

/// Provider che calcola stats osservando finance + reviews
final appStatsProvider = Provider<AppStats>((ref) {
  final ledger = ref.watch(financeProvider);
  final reviews = ref.watch(reviewsProvider);

  // Calcola total spent
  final totalSpent = ledger.fold<double>(0, (sum, e) => sum + e.totalPrice);

  // Calcola count unico (non sommare count, contare entries)
  final totalMoviesSeen = ledger.length;

  // Calcola average ticket
  final avgTicketPrice = totalMoviesSeen > 0
      ? totalSpent / totalMoviesSeen
      : 0.0;

  // Calcola average user rating
  final ratingsCount = reviews.where((r) => r.hasRating).length;
  final avgUserRating = ratingsCount > 0
      ? reviews.fold<double>(0, (sum, r) => sum + r.userRating) / ratingsCount
      : 0.0;

  // Calcola spending by month
  final spendingByMonth = <String, int>{};
  for (final entry in ledger) {
    final monthKey = entry.monthKey;
    spendingByMonth[monthKey] = (spendingByMonth[monthKey] ?? 0) + 1;
  }

  // Calcola favorite cinema
  String? favoriteCinema;
  if (ledger.isNotEmpty) {
    final cinemaCount = <String, int>{};
    for (final entry in ledger) {
      cinemaCount[entry.cinema] = (cinemaCount[entry.cinema] ?? 0) + 1;
    }
    favoriteCinema = cinemaCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  return AppStats(
    totalSpent: totalSpent,
    totalMoviesSeen: totalMoviesSeen,
    avgTicketPrice: avgTicketPrice,
    avgUserRating: avgUserRating,
    spendingByMonth: spendingByMonth,
    favoriteCinema: favoriteCinema,
  );
});
