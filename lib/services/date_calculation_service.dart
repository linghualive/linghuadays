class DateCalculationResult {
  final int days;
  final int hours;
  final int minutes;
  final int seconds;

  const DateCalculationResult({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });
}

class DateCalculationService {
  /// 计算距目标日期的天数
  /// 正数=未来（还有X天），负数=过去（已过X天），0=今天
  int daysUntil(DateTime targetDate, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  /// 计算每年重复事件的下一次公历日期
  DateTime nextOccurrence(DateTime targetDate, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 今年的日期
    var next = DateTime(today.year, targetDate.month, targetDate.day);

    // 处理2月29日的情况
    if (targetDate.month == 2 && targetDate.day == 29) {
      if (!_isLeapYear(today.year)) {
        // 非闰年，使用2月28日
        next = DateTime(today.year, 2, 28);
      }
    }

    // 如果今年的日期已过，使用明年的
    if (next.isBefore(today)) {
      final nextYear = today.year + 1;
      if (targetDate.month == 2 && targetDate.day == 29) {
        // 找到下一个闰年
        var year = nextYear;
        while (!_isLeapYear(year)) {
          year++;
        }
        next = DateTime(year, 2, 29);
      } else {
        next = DateTime(nextYear, targetDate.month, targetDate.day);
      }
    }

    return next;
  }

  /// 计算距目标日期的天/时/分/秒（用于实时倒计时）
  DateCalculationResult timeUntil(DateTime targetDate, {DateTime? from}) {
    final now = from ?? DateTime.now();
    final diff = targetDate.difference(now);

    if (diff.isNegative) {
      return const DateCalculationResult(
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
      );
    }

    final totalSeconds = diff.inSeconds;
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return DateCalculationResult(
      days: days,
      hours: hours,
      minutes: minutes,
      seconds: seconds,
    );
  }

  /// 计算两个日期之间的年、月、天差值
  ({int years, int months, int days}) yearsMonthsDaysBetween(
    DateTime from,
    DateTime to,
  ) {
    // 确保 from <= to
    if (from.isAfter(to)) {
      final temp = from;
      from = to;
      to = temp;
    }

    int years = to.year - from.year;
    int months = to.month - from.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    // 计算中间日期：from + years 年 + months 月
    DateTime intermediate = _addMonths(from, years * 12 + months);

    // 如果中间日期超过 to，说明多算了一个月
    if (intermediate.isAfter(to)) {
      months--;
      if (months < 0) {
        years--;
        months += 12;
      }
      intermediate = _addMonths(from, years * 12 + months);
    }

    final days = to.difference(intermediate).inDays;

    return (years: years, months: months, days: days);
  }

  /// 给日期加上指定月数，日期超出当月最大天数时自动截断
  DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year + months ~/ 12;
    int newMonth = date.month + months % 12;
    if (newMonth > 12) {
      newYear++;
      newMonth -= 12;
    }
    final maxDay = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = date.day > maxDay ? maxDay : date.day;
    return DateTime(newYear, newMonth, newDay);
  }

  /// 计算两个日期之间的月、天差值
  ({int months, int days}) monthsDaysBetween(DateTime from, DateTime to) {
    final result = yearsMonthsDaysBetween(from, to);
    return (months: result.years * 12 + result.months, days: result.days);
  }

  /// 将总天数转换为周、天
  ({int weeks, int days}) weeksDaysBetween(int totalDays) {
    final abs = totalDays.abs();
    return (weeks: abs ~/ 7, days: abs % 7);
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}
