import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/category_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/style_repository.dart';
import '../services/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(databaseHelperProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseHelperProvider));
});

final styleRepositoryProvider = Provider<StyleRepository>((ref) {
  return StyleRepository(ref.watch(databaseHelperProvider));
});
