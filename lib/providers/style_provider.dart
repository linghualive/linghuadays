import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_style.dart';
import 'database_provider.dart';

final stylesProvider =
    AsyncNotifierProvider<StylesNotifier, List<CardStyle>>(
  StylesNotifier.new,
);

class StylesNotifier extends AsyncNotifier<List<CardStyle>> {
  @override
  Future<List<CardStyle>> build() async {
    final repo = ref.watch(styleRepositoryProvider);
    await repo.initPresets();
    return repo.getAll();
  }

  Future<int> addStyle(CardStyle style) async {
    final repo = ref.read(styleRepositoryProvider);
    final id = await repo.insert(style);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateStyle(CardStyle style) async {
    final repo = ref.read(styleRepositoryProvider);
    await repo.update(style);
    ref.invalidateSelf();
  }

  Future<void> deleteStyle(int id) async {
    final repo = ref.read(styleRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}
