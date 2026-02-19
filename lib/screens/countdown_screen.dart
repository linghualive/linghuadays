import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/event.dart';
import '../services/date_calculation_service.dart';

class CountdownScreen extends StatefulWidget {
  final Event event;

  const CountdownScreen({super.key, required this.event});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  late DateCalculationResult _timeLeft;
  final _calcService = DateCalculationService();
  bool _showOverlay = true;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // 强制横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 全屏沉浸模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 屏幕常亮
    WakelockPlus.enable();

    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    // 恢复竖屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 关闭屏幕常亮
    WakelockPlus.disable();
    super.dispose();
  }

  void _updateTime() {
    final targetEnd = DateTime(
      widget.event.targetDate.year,
      widget.event.targetDate.month,
      widget.event.targetDate.day,
      23,
      59,
      59,
    );
    final result = _calcService.timeUntil(targetEnd);
    setState(() {
      _timeLeft = result;
      _isFinished = result.days == 0 &&
          result.hours == 0 &&
          result.minutes == 0 &&
          result.seconds == 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showOverlay = !_showOverlay),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 200) {
            Navigator.pop(context);
          }
        },
        child: Stack(
          children: [
            // 主内容
            Center(
              child: _isFinished
                  ? _buildFinishedView(size)
                  : _buildCountdownView(size),
            ),
            // 顶部信息栏
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.event.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatTargetDate(),
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownView(Size size) {
    final numberStyle = GoogleFonts.robotoMono(
      fontSize: size.width * 0.08,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF00E5FF),
    );
    final labelStyle = TextStyle(
      fontSize: size.width * 0.02,
      color: Colors.white38,
      letterSpacing: 2,
    );
    final separatorStyle = TextStyle(
      fontSize: size.width * 0.06,
      fontWeight: FontWeight.w300,
      color: Colors.white24,
    );

    final segments = <Widget>[];

    if (_timeLeft.days > 0) {
      segments.addAll([
        _buildTimeSegment(
          _timeLeft.days.toString().padLeft(2, '0'),
          '天',
          numberStyle,
          labelStyle,
        ),
        Text(' : ', style: separatorStyle),
      ]);
    }

    if (_timeLeft.days > 0 || _timeLeft.hours > 0) {
      segments.addAll([
        _buildTimeSegment(
          _timeLeft.hours.toString().padLeft(2, '0'),
          '时',
          numberStyle,
          labelStyle,
        ),
        Text(' : ', style: separatorStyle),
      ]);
    }

    segments.addAll([
      _buildTimeSegment(
        _timeLeft.minutes.toString().padLeft(2, '0'),
        '分',
        numberStyle,
        labelStyle,
      ),
      Text(' : ', style: separatorStyle),
      _buildTimeSegment(
        _timeLeft.seconds.toString().padLeft(2, '0'),
        '秒',
        numberStyle,
        labelStyle,
      ),
    ]);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: segments,
    );
  }

  Widget _buildTimeSegment(
    String value,
    String label,
    TextStyle numberStyle,
    TextStyle labelStyle,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: numberStyle),
        const SizedBox(height: 4),
        Text(label, style: labelStyle),
      ],
    );
  }

  Widget _buildFinishedView(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.celebration,
          size: size.width * 0.1,
          color: const Color(0xFFFFD54F),
        ),
        const SizedBox(height: 24),
        Text(
          '时刻已到',
          style: GoogleFonts.robotoMono(
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFD54F),
          ),
        ),
      ],
    );
  }

  String _formatTargetDate() {
    final d = widget.event.targetDate;
    return '${d.year}年${d.month}月${d.day}日';
  }
}
