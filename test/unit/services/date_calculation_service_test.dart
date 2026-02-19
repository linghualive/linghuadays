import 'package:flutter_test/flutter_test.dart';
import 'package:daysmater/services/date_calculation_service.dart';

void main() {
  late DateCalculationService service;

  setUp(() {
    service = DateCalculationService();
  });

  group('daysUntil', () {
    test('未来日期返回正数', () {
      final from = DateTime(2026, 2, 19);
      final target = DateTime(2026, 2, 24);
      expect(service.daysUntil(target, from: from), 5);
    });

    test('过去日期返回负数', () {
      final from = DateTime(2026, 2, 19);
      final target = DateTime(2026, 2, 14);
      expect(service.daysUntil(target, from: from), -5);
    });

    test('当天返回0', () {
      final from = DateTime(2026, 2, 19, 15, 30);
      final target = DateTime(2026, 2, 19);
      expect(service.daysUntil(target, from: from), 0);
    });

    test('跨年计算正确', () {
      final from = DateTime(2026, 12, 30);
      final target = DateTime(2027, 1, 2);
      expect(service.daysUntil(target, from: from), 3);
    });

    test('闰年2月29日计算正确', () {
      final from = DateTime(2024, 2, 28);
      final target = DateTime(2024, 2, 29);
      expect(service.daysUntil(target, from: from), 1);
    });

    test('忽略时间部分，只比较日期', () {
      final from = DateTime(2026, 2, 19, 23, 59, 59);
      final target = DateTime(2026, 2, 20, 0, 0, 1);
      expect(service.daysUntil(target, from: from), 1);
    });
  });

  group('nextOccurrence', () {
    test('今年的日期还没过，返回今年', () {
      final from = DateTime(2026, 2, 19);
      final target = DateTime(2000, 5, 15);
      final next = service.nextOccurrence(target, from: from);
      expect(next, DateTime(2026, 5, 15));
    });

    test('今年的日期已过，返回明年', () {
      final from = DateTime(2026, 6, 1);
      final target = DateTime(2000, 5, 15);
      final next = service.nextOccurrence(target, from: from);
      expect(next, DateTime(2027, 5, 15));
    });

    test('今天就是目标日期，返回今天', () {
      final from = DateTime(2026, 5, 15);
      final target = DateTime(2000, 5, 15);
      final next = service.nextOccurrence(target, from: from);
      expect(next, DateTime(2026, 5, 15));
    });

    test('2月29日在非闰年使用2月28日', () {
      final from = DateTime(2026, 1, 1); // 2026非闰年
      final target = DateTime(2024, 2, 29);
      final next = service.nextOccurrence(target, from: from);
      expect(next, DateTime(2026, 2, 28));
    });

    test('2月29日已过，找下一个闰年', () {
      final from = DateTime(2026, 3, 1); // 2026非闰年，2月28日已过
      final target = DateTime(2024, 2, 29);
      final next = service.nextOccurrence(target, from: from);
      expect(next, DateTime(2028, 2, 29)); // 2028是闰年
    });
  });

  group('timeUntil', () {
    test('计算天时分秒正确', () {
      final from = DateTime(2026, 2, 19, 10, 0, 0);
      final target = DateTime(2026, 2, 21, 15, 30, 45);
      final result = service.timeUntil(target, from: from);

      expect(result.days, 2);
      expect(result.hours, 5);
      expect(result.minutes, 30);
      expect(result.seconds, 45);
    });

    test('不足一天只有时分秒', () {
      final from = DateTime(2026, 2, 19, 10, 0, 0);
      final target = DateTime(2026, 2, 19, 18, 45, 30);
      final result = service.timeUntil(target, from: from);

      expect(result.days, 0);
      expect(result.hours, 8);
      expect(result.minutes, 45);
      expect(result.seconds, 30);
    });

    test('不足一小时只有分秒', () {
      final from = DateTime(2026, 2, 19, 10, 0, 0);
      final target = DateTime(2026, 2, 19, 10, 30, 15);
      final result = service.timeUntil(target, from: from);

      expect(result.days, 0);
      expect(result.hours, 0);
      expect(result.minutes, 30);
      expect(result.seconds, 15);
    });

    test('目标已过返回全零', () {
      final from = DateTime(2026, 2, 19, 10, 0, 0);
      final target = DateTime(2026, 2, 18, 10, 0, 0);
      final result = service.timeUntil(target, from: from);

      expect(result.days, 0);
      expect(result.hours, 0);
      expect(result.minutes, 0);
      expect(result.seconds, 0);
    });

    test('恰好归零', () {
      final now = DateTime(2026, 2, 19, 10, 0, 0);
      final result = service.timeUntil(now, from: now);

      expect(result.days, 0);
      expect(result.hours, 0);
      expect(result.minutes, 0);
      expect(result.seconds, 0);
    });
  });

  group('yearsMonthsDaysBetween', () {
    test('同一天返回全零', () {
      final date = DateTime(2026, 2, 19);
      final result = service.yearsMonthsDaysBetween(date, date);
      expect(result.years, 0);
      expect(result.months, 0);
      expect(result.days, 0);
    });

    test('相差整年', () {
      final from = DateTime(2024, 3, 15);
      final to = DateTime(2026, 3, 15);
      final result = service.yearsMonthsDaysBetween(from, to);
      expect(result.years, 2);
      expect(result.months, 0);
      expect(result.days, 0);
    });

    test('跨月份有余天', () {
      final from = DateTime(2026, 1, 20);
      final to = DateTime(2026, 3, 5);
      final result = service.yearsMonthsDaysBetween(from, to);
      expect(result.years, 0);
      expect(result.months, 1);
      expect(result.days, 13);
    });

    test('跨年计算', () {
      final from = DateTime(2025, 10, 15);
      final to = DateTime(2026, 2, 19);
      final result = service.yearsMonthsDaysBetween(from, to);
      expect(result.years, 0);
      expect(result.months, 4);
      expect(result.days, 4);
    });

    test('参数顺序无关（自动取绝对值）', () {
      final from = DateTime(2026, 2, 19);
      final to = DateTime(2025, 10, 15);
      final result = service.yearsMonthsDaysBetween(from, to);
      expect(result.years, 0);
      expect(result.months, 4);
      expect(result.days, 4);
    });

    test('月末边界（1月31日到3月1日）', () {
      final from = DateTime(2026, 1, 31);
      final to = DateTime(2026, 3, 1);
      final result = service.yearsMonthsDaysBetween(from, to);
      expect(result.years, 0);
      expect(result.months, 1);
      expect(result.days, 1);
    });
  });

  group('monthsDaysBetween', () {
    test('超过一年按总月数计算', () {
      final from = DateTime(2024, 3, 15);
      final to = DateTime(2026, 3, 15);
      final result = service.monthsDaysBetween(from, to);
      expect(result.months, 24);
      expect(result.days, 0);
    });

    test('不足一个月只有天数', () {
      final from = DateTime(2026, 2, 10);
      final to = DateTime(2026, 2, 19);
      final result = service.monthsDaysBetween(from, to);
      expect(result.months, 0);
      expect(result.days, 9);
    });
  });

  group('weeksDaysBetween', () {
    test('整周无余天', () {
      final result = service.weeksDaysBetween(14);
      expect(result.weeks, 2);
      expect(result.days, 0);
    });

    test('有余天', () {
      final result = service.weeksDaysBetween(10);
      expect(result.weeks, 1);
      expect(result.days, 3);
    });

    test('不足一周', () {
      final result = service.weeksDaysBetween(5);
      expect(result.weeks, 0);
      expect(result.days, 5);
    });

    test('负数取绝对值', () {
      final result = service.weeksDaysBetween(-10);
      expect(result.weeks, 1);
      expect(result.days, 3);
    });

    test('零天', () {
      final result = service.weeksDaysBetween(0);
      expect(result.weeks, 0);
      expect(result.days, 0);
    });
  });
}
