import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daysmater/models/card_style.dart';
import 'package:daysmater/repositories/style_repository.dart';
import 'package:daysmater/services/database_helper.dart';

void main() {
  late DatabaseHelper dbHelper;
  late StyleRepository repo;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    dbHelper = DatabaseHelper(
      databaseFactory: databaseFactoryFfi,
      inMemory: true,
    );
    repo = StyleRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('StyleRepository', () {
    test('insert 和 getById', () async {
      const style = CardStyle(
        styleName: '自定义风格',
        styleType: StyleType.custom,
        backgroundColor: 0xFF000000,
        textColor: 0xFFFFFFFF,
        numberColor: 0xFFFFFFFF,
      );
      final id = await repo.insert(style);
      final result = await repo.getById(id);
      expect(result, isNotNull);
      expect(result!.styleName, '自定义风格');
    });

    test('initPresets 初始化12种预设风格', () async {
      await repo.initPresets();
      final styles = await repo.getAll();
      expect(styles.length, 12);
    });

    test('initPresets 不重复初始化', () async {
      await repo.initPresets();
      await repo.initPresets();
      final styles = await repo.getAll();
      expect(styles.length, 12);
    });

    test('delete 预设风格抛异常', () async {
      await repo.initPresets();
      final styles = await repo.getAll();
      final presetId = styles.first.id!;

      expect(
        () => repo.delete(presetId),
        throwsStateError,
      );
    });

    test('delete 自定义风格成功', () async {
      final id = await repo.insert(const CardStyle(
        styleName: '临时',
        styleType: StyleType.custom,
        backgroundColor: 0xFF000000,
        textColor: 0xFFFFFFFF,
        numberColor: 0xFFFFFFFF,
      ));

      await repo.delete(id);
      final result = await repo.getById(id);
      expect(result, isNull);
    });

    test('update 更新风格', () async {
      final id = await repo.insert(const CardStyle(
        styleName: '原风格',
        styleType: StyleType.custom,
        backgroundColor: 0xFF000000,
        textColor: 0xFFFFFFFF,
        numberColor: 0xFFFFFFFF,
      ));

      final style = (await repo.getById(id))!;
      await repo.update(style.copyWith(
        styleName: '新风格',
        backgroundColor: 0xFFFF0000,
      ));

      final updated = await repo.getById(id);
      expect(updated!.styleName, '新风格');
      expect(updated.backgroundColor, 0xFFFF0000);
    });

    test('getAll 预设风格排在前面', () async {
      await repo.initPresets();
      await repo.insert(const CardStyle(
        styleName: 'AAA自定义',
        styleType: StyleType.custom,
        backgroundColor: 0xFF000000,
        textColor: 0xFFFFFFFF,
        numberColor: 0xFFFFFFFF,
      ));

      final styles = await repo.getAll();
      // 前12个是预设
      for (var i = 0; i < 12; i++) {
        expect(styles[i].isPreset, true);
      }
      expect(styles.last.isPreset, false);
    });
  });
}
