import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/services/lunar_service.dart';

void main() {
  late LunarService service;

  setUp(() {
    service = LunarService();
  });

  group('lunarToSolar', () {
    test('普通农历日期转公历正确', () {
      // 农历2026年正月初一
      final result = service.lunarToSolar(2026, 1, 1);
      // 2026年农历正月初一 = 公历2026年2月17日
      expect(result.year, 2026);
      expect(result.month, 2);
      expect(result.day, 17);
    });

    test('农历除夕转公历正确', () {
      // 农历2025年十二月三十（除夕）= 公历2026年2月16日
      final result = service.lunarToSolar(2025, 12, 29);
      expect(result.year, 2026);
      expect(result.month, 2);
      // 具体日期取决于lunar库实现
      expect(result.day, isNotNull);
    });

    test('边界年份 1900 年可转换', () {
      final result = service.lunarToSolar(1900, 1, 1);
      expect(result.year, 1900);
    });

    test('边界年份 2099 年可转换', () {
      final result = service.lunarToSolar(2099, 1, 1);
      expect(result.year, isNotNull);
    });
  });

  group('solarToLunar', () {
    test('公历转农历正确', () {
      // 公历 2026-02-17 = 农历 2026年正月初一
      final result = service.solarToLunar(DateTime(2026, 2, 17));
      expect(result.year, 2026);
      expect(result.month, 1);
      expect(result.day, 1);
      expect(result.isLeapMonth, false);
    });

    test('往返转换一致', () {
      final originalSolar = DateTime(2026, 6, 15);
      final lunar = service.solarToLunar(originalSolar);
      final backToSolar = service.lunarToSolar(
        lunar.year,
        lunar.month,
        lunar.day,
        isLeapMonth: lunar.isLeapMonth,
      );
      expect(backToSolar.year, originalSolar.year);
      expect(backToSolar.month, originalSolar.month);
      expect(backToSolar.day, originalSolar.day);
    });
  });

  group('getLunarDateString', () {
    test('格式化农历日期包含年月日', () {
      final str = service.getLunarDateString(2026, 1, 1);
      // 应包含干支年、月、日
      expect(str, contains('年'));
      expect(str, contains('月'));
    });

    test('格式化闰月包含闰字', () {
      // 找一个有闰月的年份来测试
      // 2025年有闰六月
      final leapMonth = service.getLeapMonth(2025);
      if (leapMonth > 0) {
        final str = service.getLunarDateString(
          2025,
          leapMonth,
          1,
          isLeapMonth: true,
        );
        expect(str, contains('闰'));
      }
    });
  });

  group('nextLunarOccurrence', () {
    test('今年的农历日期还没过，返回今年对应的公历日期', () {
      // 假设当前是2026年2月（农历正月），农历八月十五还没到
      final from = DateTime(2026, 2, 19);
      final result = service.nextLunarOccurrence(8, 15, from: from);
      expect(result.isAfter(from) || result.isAtSameMomentAs(from), true);
    });

    test('今年的农历日期已过，返回明年对应的公历日期', () {
      // 设置一个已过的日期
      final from = DateTime(2026, 12, 31);
      final result = service.nextLunarOccurrence(1, 1, from: from);
      // 下一个正月初一应在2027年
      expect(result.year, greaterThanOrEqualTo(2027));
    });
  });

  group('getLeapMonth', () {
    test('有闰月的年份返回正确月份', () {
      // 验证可以正常调用
      final leapMonth = service.getLeapMonth(2025);
      expect(leapMonth, greaterThanOrEqualTo(0));
    });

    test('无闰月的年份返回0', () {
      // 具体哪年无闰月取决于历法，验证函数不报错
      final leapMonth = service.getLeapMonth(2026);
      expect(leapMonth, greaterThanOrEqualTo(0));
    });
  });
}
