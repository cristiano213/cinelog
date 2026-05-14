import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/finance_entry.dart';
import '../models/user_review.dart';
import '../models/cinema_note.dart';
import '../models/wishlist.dart';
import '../models/library_archive.dart';

class LocalStorageService {
  static const String _financeKey = 'finance_ledger';
  static const String _reviewsKey = 'user_reviews';
  static const String _cinemaNotesKey = 'cinema_notes';
  static const String _wishlistKey = 'wishlist';
  static const String _archiveKey = 'library_archive';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==========================
  // FINANCE LEDGER
  // ==========================

  Future<List<FinanceLedgerEntry>> loadFinanceLedger() async {
    try {
      final json = _prefs.getString(_financeKey);
      if (json == null) return [];

      final list = jsonDecode(json) as List;
      return list
          .map((item) => FinanceLedgerEntry.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading finance ledger: $e');
      return [];
    }
  }

  Future<void> saveFinanceLedger(List<FinanceLedgerEntry> entries) async {
    try {
      final json = jsonEncode(entries.map((e) => e.toJson()).toList());
      await _prefs.setString(_financeKey, json);
    } catch (e) {
      print('Error saving finance ledger: $e');
    }
  }

  // ==========================
  // USER REVIEWS
  // ==========================

  Future<List<UserReview>> loadUserReviews() async {
    try {
      final json = _prefs.getString(_reviewsKey);
      if (json == null) return [];

      final list = jsonDecode(json) as List;
      return list
          .map((item) => UserReview.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading reviews: $e');
      return [];
    }
  }

  Future<void> saveUserReviews(List<UserReview> reviews) async {
    try {
      final json = jsonEncode(reviews.map((r) => r.toJson()).toList());
      await _prefs.setString(_reviewsKey, json);
    } catch (e) {
      print('Error saving reviews: $e');
    }
  }

  // ==========================
  // CINEMA NOTES
  // ==========================

  Future<List<CinemaNote>> loadCinemaNotes() async {
    try {
      final json = _prefs.getString(_cinemaNotesKey);
      if (json == null) return [];

      final list = jsonDecode(json) as List;
      return list
          .map((item) => CinemaNote.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading cinema notes: $e');
      return [];
    }
  }

  Future<void> saveCinemaNotes(List<CinemaNote> notes) async {
    try {
      final json = jsonEncode(notes.map((n) => n.toJson()).toList());
      await _prefs.setString(_cinemaNotesKey, json);
    } catch (e) {
      print('Error saving cinema notes: $e');
    }
  }

  // ==========================
  // WISHLIST
  // ==========================

  Future<Wishlist> loadWishlist() async {
    try {
      final json = _prefs.getString(_wishlistKey);
      if (json == null) return Wishlist(films: []);

      final data = jsonDecode(json) as Map<String, dynamic>;
      return Wishlist.fromJson(data);
    } catch (e) {
      print('Error loading wishlist: $e');
      return Wishlist(films: []);
    }
  }

  Future<void> saveWishlist(Wishlist wishlist) async {
    try {
      final json = jsonEncode(wishlist.toJson());
      await _prefs.setString(_wishlistKey, json);
    } catch (e) {
      print('Error saving wishlist: $e');
    }
  }

  // ==========================
  // LIBRARY ARCHIVE
  // ==========================

  Future<LibraryArchive> loadLibraryArchive() async {
    try {
      final json = _prefs.getString(_archiveKey);
      if (json == null) return LibraryArchive(films: []);

      final data = jsonDecode(json) as Map<String, dynamic>;
      return LibraryArchive.fromJson(data);
    } catch (e) {
      print('Error loading library archive: $e');
      return LibraryArchive(films: []);
    }
  }

  Future<void> saveLibraryArchive(LibraryArchive archive) async {
    try {
      final json = jsonEncode(archive.toJson());
      await _prefs.setString(_archiveKey, json);
    } catch (e) {
      print('Error saving library archive: $e');
    }
  }

  // ==========================
  // BULK EXPORT/IMPORT
  // ==========================

  Future<String> exportAllDataAsJson() async {
    try {
      final ledger = await loadFinanceLedger();
      final reviews = await loadUserReviews();
      final notes = await loadCinemaNotes();
      final wishlist = await loadWishlist();
      final archive = await loadLibraryArchive();

      final data = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'finance_ledger': ledger.map((e) => e.toJson()).toList(),
        'user_reviews': reviews.map((r) => r.toJson()).toList(),
        'cinema_notes': notes.map((n) => n.toJson()).toList(),
        'wishlist': wishlist.toJson(),
        'library_archive': archive.toJson(),
      };

      return jsonEncode(data);
    } catch (e) {
      print('Error exporting data: $e');
      return '{}';
    }
  }

  Future<void> importDataFromJson(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map;

      // Finance Ledger
      if (data['finance_ledger'] != null) {
        final ledger = (data['finance_ledger'] as List)
            .map((e) => FinanceLedgerEntry.fromJson(e))
            .toList();
        await saveFinanceLedger(ledger);
      }

      // Reviews
      if (data['user_reviews'] != null) {
        final reviews = (data['user_reviews'] as List)
            .map((r) => UserReview.fromJson(r))
            .toList();
        await saveUserReviews(reviews);
      }

      // Cinema Notes
      if (data['cinema_notes'] != null) {
        final notes = (data['cinema_notes'] as List)
            .map((n) => CinemaNote.fromJson(n))
            .toList();
        await saveCinemaNotes(notes);
      }

      // Wishlist
      if (data['wishlist'] != null) {
        final wishlist = Wishlist.fromJson(data['wishlist']);
        await saveWishlist(wishlist);
      }

      // Archive
      if (data['library_archive'] != null) {
        final archive = LibraryArchive.fromJson(data['library_archive']);
        await saveLibraryArchive(archive);
      }
    } catch (e) {
      print('Error importing data: $e');
    }
  }

  // ==========================
  // CLEAR ALL
  // ==========================

  Future<void> clearAll() async {
    try {
      await _prefs.remove(_financeKey);
      await _prefs.remove(_reviewsKey);
      await _prefs.remove(_cinemaNotesKey);
      await _prefs.remove(_wishlistKey);
      await _prefs.remove(_archiveKey);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
