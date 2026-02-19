import 'package:lunar/lunar.dart';

class LunarService {
  /// 农历转公历
  DateTime lunarToSolar(
    int year,
    int month,
    int day, {
    bool isLeapMonth = false,
  }) {
    final lunar = Lunar.fromYmd(year, isLeapMonth ? -month : month, day);
    final solar = lunar.getSolar();
    return DateTime(solar.getYear(), solar.getMonth(), solar.getDay());
  }

  /// 公历转农历，返回 (year, month, day, isLeapMonth)
  ({int year, int month, int day, bool isLeapMonth}) solarToLunar(
    DateTime date,
  ) {
    final solar = Solar.fromYmd(date.year, date.month, date.day);
    final lunar = solar.getLunar();
    final month = lunar.getMonth();
    return (
      year: lunar.getYear(),
      month: month.abs(),
      day: lunar.getDay(),
      isLeapMonth: month < 0,
    );
  }

  /// 格式化农历日期文本（如"甲辰年腊月廿三"）
  String getLunarDateString(int year, int month, int day,
      {bool isLeapMonth = false,}) {
    final lunar = Lunar.fromYmd(year, isLeapMonth ? -month : month, day);
    final yearGanZhi = lunar.getYearInGanZhi();
    final monthName = lunar.getMonthInChinese();
    final dayName = lunar.getDayInChinese();
    final leapPrefix = isLeapMonth ? '闰' : '';
    return '$yearGanZhi年$leapPrefix$monthName月$dayName';
  }

  /// 计算农历重复事件的下一次公历日期
  DateTime nextLunarOccurrence(
    int lunarMonth,
    int lunarDay, {
    bool isLeapMonth = false,
    DateTime? from,
  }) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 获取今年对应的农历年
    final currentLunar = solarToLunar(today);
    final lunarYear = currentLunar.year;

    // 尝试今年
    try {
      final thisYear = lunarToSolar(lunarYear, lunarMonth, lunarDay,
          isLeapMonth: isLeapMonth,);
      if (!thisYear.isBefore(today)) {
        return thisYear;
      }
    } catch (_) {
      // 今年该农历日期不存在（如闰月不存在），尝试下一年
    }

    // 尝试后续年份（最多搜索5年以处理闰月）
    for (var i = 1; i <= 5; i++) {
      try {
        final nextYear = lunarToSolar(lunarYear + i, lunarMonth, lunarDay,
            isLeapMonth: isLeapMonth,);
        return nextYear;
      } catch (_) {
        continue;
      }
    }

    // fallback: 非闰月的同一天
    return lunarToSolar(lunarYear + 1, lunarMonth, lunarDay);
  }

  /// 获取某农历年的闰月（0表示无闰月）
  int getLeapMonth(int lunarYear) {
    final lunar = Lunar.fromYmd(lunarYear, 1, 1);
    return LunarYear.fromYear(lunar.getYear()).getLeapMonth();
  }

  /// 获取某农历月的天数
  int getDaysInLunarMonth(int lunarYear, int lunarMonth,
      {bool isLeapMonth = false,}) {
    final year = LunarYear.fromYear(lunarYear);
    final months = year.getMonths();
    for (final m in months) {
      if (m.getMonth() == lunarMonth &&
          ((isLeapMonth && m.getMonth() < 0) ||
              (!isLeapMonth && m.getMonth() > 0))) {
        return m.getDayCount();
      }
    }
    // 默认30天
    return 30;
  }
}
