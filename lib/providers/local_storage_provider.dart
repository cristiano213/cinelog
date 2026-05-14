import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/local_storage_service.dart';

/// Provider singleton per LocalStorageService
final localStorageServiceProvider = Provider((ref) {
  return LocalStorageService();
});
