import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'database_provider.dart';

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<EventCategory>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<EventCategory>> {
  @override
  Future<List<EventCategory>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    await repo.initPresets();
    return repo.getAll();
  }

  Future<void> addCategory(EventCategory category) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.insert(category);
    ref.invalidateSelf();
  }

  Future<void> updateCategory(EventCategory category) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.update(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(int id) async {
    final repo = ref.read(categoryRepositoryProvider);
    // 先清除该分类下事件的 categoryId
    final eventRepo = ref.read(
      eventRepositoryProvider,
    );
    await eventRepo.clearCategoryFromEvents(id);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}
