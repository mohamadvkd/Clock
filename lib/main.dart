import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ClockStore.init();
  runApp(const ClockApp());
}

class ClockStore {
  static late SharedPreferences prefs;

  static const _kDark = 'clock_dark';
  static const _kAlarms = 'clock_alarms';
  static const _kWorldCities = 'clock_world_cities';

  static bool isDark = true;
  static List<Alarm> alarms = [];
  static Set<String> worldCities = {'الرياض', 'لندن', 'نيويورك', 'طوكيو'};

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool(_kDark) ?? true;

    final alarmsRaw = prefs.getString(_kAlarms);
    if (alarmsRaw != null) {
      alarms = (jsonDecode(alarmsRaw) as List)
          .map((e) => Alarm.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final citiesRaw = prefs.getString(_kWorldCities);
    if (citiesRaw != null) {
      worldCities = (jsonDecode(citiesRaw) as List).cast<String>().toSet();
    }
  }

  static Future<void> saveDark(bool v) async {
    isDark = v;
    await prefs.setBool(_kDark, v);
  }

  static Future<void> saveAlarms() async {
    await prefs.setString(
      _kAlarms,
      jsonEncode(alarms.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> saveCities() async {
    await prefs.setString(
      _kWorldCities,
      jsonEncode(worldCities.toList()),
    );
  }
}

class Alarm {
  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.label,
    this.enabled = true,
  });

  final String id;
  int hour;
  int minute;
  String label;
  bool enabled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'label': label,
        'enabled': enabled,
      };

  factory Alarm.fromJson(Map<String, dynamic> j) => Alarm(
        id: j['id'] as String,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        label: j['label'] as String,
        enabled: j['enabled'] as bool? ?? true,
      );
}

class WorldCity {
  const WorldCity({
    required this.name,
    required this.country,
    required this.offsetHours,
    required this.icon,
  });

  final String name;
  final String country;
  final int offsetHours;
  final IconData icon;

  DateTime get time => DateTime.now().toUtc().add(Duration(hours: offsetHours));

  bool get isDay => time.hour >= 6 && time.hour < 18;
}

const worldCitiesData = <WorldCity>[
  WorldCity(
    name: 'الرياض',
    country: 'السعودية',
    offsetHours: 3,
    icon: Icons.mosque_outlined,
  ),
  WorldCity(
    name: 'دبي',
    country: 'الإمارات',
    offsetHours: 4,
    icon: Icons.location_city_outlined,
  ),
  WorldCity(
    name: 'القاهرة',
    country: 'مصر',
    offsetHours: 2,
    icon: Icons.temple_buddhist_outlined,
  ),
  WorldCity(
    name: 'لندن',
    country: 'بريطانيا',
    offsetHours: 0,
    icon: Icons.architecture_outlined,
  ),
  WorldCity(
    name: 'باريس',
    country: 'فرنسا',
    offsetHours: 1,
    icon: Icons.local_cafe_outlined,
  ),
  WorldCity(
    name: 'نيويورك',
    country: 'أمريكا',
    offsetHours: -5,
    icon: Icons.location_city,
  ),
  WorldCity(
    name: 'طوكيو',
    country: 'اليابان',
    offsetHours: 9,
    icon: Icons.temple_hindu_outlined,
  ),
  WorldCity(
    name: 'سيدني',
    country: 'أستراليا',
    offsetHours: 10,
    icon: Icons.beach_access_outlined,
  ),
  WorldCity(
    name: 'مكة',
    country: 'السعودية',
    offsetHours: 3,
    icon: Icons.mosque,
  ),
  WorldCity(
    name: 'اسطنبول',
    country: 'تركيا',
    offsetHours: 3,
    icon: Icons.church_outlined,
  ),
];

class ClockApp extends StatefulWidget {
  const ClockApp({super.key});

  @override
  State<ClockApp> createState() => _ClockAppState();
}

class _ClockAppState extends State<ClockApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clock',
      theme: ClockTheme.light,
      darkTheme: ClockTheme.dark,
      themeMode: ClockStore.isDark ? ThemeMode.dark : ThemeMode.light,
      home: ClockHome(
        onThemeChanged: () => setState(() {}),
      ),
    );
  }
}

class ClockHome extends StatefulWidget {
  const ClockHome({super.key, required this.onThemeChanged});

  final VoidCallback onThemeChanged;

  @override
  State<ClockHome> createState() => _ClockHomeState();
}

class _ClockHomeState extends State<ClockHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الساعة'),
        actions: [
          IconButton(
            tooltip: 'الأدوات',
            onPressed: () => _openTools(),
            icon: const Icon(Icons.widgets_outlined),
          ),
          IconButton(
            tooltip: 'الوضع الليلي',
            onPressed: () {
              ClockStore.saveDark(!ClockStore.isDark);
              widget.onThemeChanged();
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                ClockStore.isDark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                key: ValueKey(ClockStore.isDark),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          ClockTab(),
          StopwatchTab(),
          TimerTab(),
          WorldClockTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (v) => setState(() => _tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'الساعة',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'الإيقاف',
          ),
          NavigationDestination(
            icon: Icon(Icons.hourglass_empty),
            selectedIcon: Icon(Icons.hourglass_full),
            label: 'المؤقت',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'العالمية',
          ),
        ],
      ),
    );
  }

  void _openTools() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ToolsSheet(),
    );
  }
}

class ClockTab extends StatefulWidget {
  const ClockTab({super.key});

  @override
  State<ClockTab> createState() => _ClockTabState();
}

class _ClockTabState extends State<ClockTab> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        _analogClock(),
        const SizedBox(height: 28),
        _digitalClock(),
        const SizedBox(height: 24),
        _dateCard(),
        const SizedBox(height: 24),
        _miniWorldRow(),
      ],
    );
  }

  Widget _analogClock() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ClockTheme.glowGradient,
              ),
            ),
            CustomPaint(
              size: const Size(240, 240),
              painter: _AnalogClockPainter(
                time: _now,
                primaryColor: ClockTheme.cyan,
                secondaryColor: ClockTheme.purple,
                textColor: ClockStore.isDark
                    ? Colors.white
                    : const Color(0xFF0A0E1A),
                tickColor: ClockStore.isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _digitalClock() {
    final hours = _now.hour.toString().padLeft(2, '0');
    final minutes = _now.minute.toString().padLeft(2, '0');
    final seconds = _now.second.toString().padLeft(2, '0');

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                hours,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedOpacity(
                  opacity: _now.second % 2 == 0 ? 1 : 0.3,
                  duration: const Duration(milliseconds: 500),
                  child: const Text(
                    ':',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: ClockTheme.cyan,
                      height: 1,
                    ),
                  ),
                ),
              ),
              Text(
                minutes,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: ClockTheme.cyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              seconds,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ClockTheme.cyan,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: ClockTheme.cyanGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _weekdayAr(_now.weekday),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_now.day} ${_monthAr(_now.month)} ${_now.year}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniWorldRow() {
    final cities = worldCitiesData
        .where((c) => ClockStore.worldCities.contains(c.name))
        .take(4)
        .toList();

    if (cities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'مدن أخرى',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final city = cities[i];
              final time = city.time;
              return Container(
                width: 120,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          city.icon,
                          size: 16,
                          color: city.isDay
                              ? ClockTheme.orange
                              : ClockTheme.purple,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            city.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _weekdayAr(int w) => const [
        '',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
        'الأحد',
      ][w];

  String _monthAr(int m) => const [
        '',
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ][m];
}

class _AnalogClockPainter extends CustomPainter {
  _AnalogClockPainter({
    required this.time,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.tickColor,
  });

  final DateTime time;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final facePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    final borderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 1, borderPaint);

    for (int i = 0; i < 60; i++) {
      final angle = (i * 6) * math.pi / 180 - math.pi / 2;
      final isHour = i % 5 == 0;
      final outer = radius - 8;
      final inner = isHour ? radius - 20 : radius - 14;

      final start = Offset(
        center.dx + inner * math.cos(angle),
        center.dy + inner * math.sin(angle),
      );
      final end = Offset(
        center.dx + outer * math.cos(angle),
        center.dy + outer * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = isHour
            ? primaryColor.withValues(alpha: 0.9)
            : tickColor.withValues(alpha: 0.5)
        ..strokeWidth = isHour ? 3 : 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, tickPaint);
    }

    final hourAngle = ((time.hour % 12) + time.minute / 60) * 30 * math.pi / 180 - math.pi / 2;
    final minuteAngle = (time.minute + time.second / 60) * 6 * math.pi / 180 - math.pi / 2;
    final secondAngle = time.second * 6 * math.pi / 180 - math.pi / 2;

    _drawHand(
      canvas,
      center,
      hourAngle,
      radius * 0.5,
      6,
      textColor,
    );
    _drawHand(
      canvas,
      center,
      minuteAngle,
      radius * 0.7,
      4,
      textColor,
    );

    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final secondEnd = Offset(
      center.dx + radius * 0.78 * math.cos(secondAngle),
      center.dy + radius * 0.78 * math.sin(secondAngle),
    );
    final secondBack = Offset(
      center.dx - radius * 0.15 * math.cos(secondAngle),
      center.dy - radius * 0.15 * math.sin(secondAngle),
    );
    canvas.drawLine(secondBack, secondEnd, glowPaint);

    final secondPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(secondBack, secondEnd, secondPaint);

    final dotPaint = Paint()..color = secondaryColor;
    canvas.drawCircle(center, 6, dotPaint);
    final innerDot = Paint()..color = primaryColor;
    canvas.drawCircle(center, 3, innerDot);
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
    Color color,
  ) {
    final end = Offset(
      center.dx + length * math.cos(angle),
      center.dy + length * math.sin(angle),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, end, paint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter old) => old.time != time;
}

class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  final Stopwatch _sw = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_sw.isRunning) {
        _sw.stop();
        _timer?.cancel();
      } else {
        _sw.start();
        _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
    HapticFeedback.lightImpact();
  }

  void _lap() {
    if (!_sw.isRunning) return;
    setState(() => _laps.insert(0, _sw.elapsed));
    HapticFeedback.selectionClick();
  }

  void _reset() {
    setState(() {
      _sw.reset();
      _sw.stop();
      _laps.clear();
      _timer?.cancel();
    });
    HapticFeedback.mediumImpact();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final mm = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$mm';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const SizedBox(height: 20),
        _ring(),
        const SizedBox(height: 28),
        _buttons(),
        const SizedBox(height: 32),
        if (_laps.isNotEmpty) _lapsList(),
      ],
    );
  }

  Widget _ring() {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(280, 280),
              painter: _ProgressRingPainter(
                progress: (_sw.elapsed.inMilliseconds % 60000) / 60000,
                color: _sw.isRunning ? ClockTheme.green : ClockTheme.cyan,
                trackColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.1),
                strokeWidth: 10,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fmt(_sw.elapsed),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _sw.isRunning ? 'قيد التشغيل' : 'متوقف',
                  style: TextStyle(
                    color: _sw.isRunning
                        ? ClockTheme.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: _sw.isRunning ? Icons.pause : Icons.play_arrow,
          color: _sw.isRunning ? ClockTheme.orange : ClockTheme.green,
          onTap: _toggle,
          size: 72,
        ),
        const SizedBox(width: 20),
        _circleButton(
          icon: Icons.flag_outlined,
          color: ClockTheme.cyan,
          onTap: _lap,
          size: 58,
        ),
        const SizedBox(width: 20),
        _circleButton(
          icon: Icons.refresh,
          color: ClockTheme.red,
          onTap: _reset,
          size: 58,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _lapsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'اللفات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${_laps.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._laps.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'لفة ${_laps.length - e.key}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    Text(
                      _fmt(e.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  int _selectedMinutes = 5;
  int _remainingSeconds = 300;
  bool _running = false;
  Timer? _ticker;
  final _presets = const [1, 3, 5, 10, 15, 30, 60];

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectPreset(int m) {
    _ticker?.cancel();
    setState(() {
      _selectedMinutes = m;
      _remainingSeconds = m * 60;
      _running = false;
    });
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
    } else {
      if (_remainingSeconds <= 0) return;
      setState(() => _running = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _ticker?.cancel();
            _running = false;
            HapticFeedback.heavyImpact();
            SystemSound.play(SystemSoundType.alert);
          }
        });
      });
    }
    HapticFeedback.lightImpact();
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  String _fmt(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _selectedMinutes * 60;
    final progress = total == 0 ? 0.0 : _remainingSeconds / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const SizedBox(height: 20),
        _ring(progress),
        const SizedBox(height: 28),
        const Text(
          'اختر المدة',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        _presetsRow(),
        const SizedBox(height: 28),
        _buttons(),
      ],
    );
  }

  Widget _ring(double progress) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(280, 280),
              painter: _ProgressRingPainter(
                progress: progress,
                color: ClockTheme.cyan,
                trackColor: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.1),
                strokeWidth: 12,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _fmt(_remainingSeconds),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _running ? 'قيد التشغيل' : 'جاهز',
                  style: TextStyle(
                    color: _running
                        ? ClockTheme.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetsRow() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = _presets[i];
          final selected = _selectedMinutes == m;
          return ChoiceChip(
            label: Text('$m د'),
            selected: selected,
            onSelected: (_) => _selectPreset(m),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          );
        },
      ),
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: _running ? Icons.pause : Icons.play_arrow,
          color: _running ? ClockTheme.orange : ClockTheme.green,
          onTap: _toggle,
          size: 72,
        ),
        const SizedBox(width: 20),
        _circleButton(
          icon: Icons.refresh,
          color: ClockTheme.red,
          onTap: _reset,
          size: 58,
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      glowPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}

class WorldClockTab extends StatefulWidget {
  const WorldClockTab({super.key});

  @override
  State<WorldClockTab> createState() => _WorldClockTabState();
}

class _WorldClockTabState extends State<WorldClockTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = worldCitiesData
        .where((c) => ClockStore.worldCities.contains(c.name))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الساعات العالمية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            FilledButton.tonal(
              onPressed: _openAddCity,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18),
                  SizedBox(width: 4),
                  Text('إضافة'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (selected.isEmpty)
          _emptyState('لم تضف أي مدينة بعد')
        else
          ...selected.asMap().entries.map(
                (e) => _cityCard(e.value, e.key),
              ),
      ],
    );
  }

  Widget _cityCard(WorldCity city, int index) {
    final time = city.time;
    final local = DateTime.now();
    final diff = city.offsetHours - local.timeZoneOffset.inHours;
    final diffLabel = diff == 0
        ? 'نفس التوقيت'
        : diff > 0
            ? '+$diff س'
            : '$diff س';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: city.isDay
                    ? const LinearGradient(
                        colors: [Color(0xFFFF9100), Color(0xFFFFB300)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF5B6BF5)],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                city.isDay
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_outlined,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${city.country} • $diffLabel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${time.day}/${time.month}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                setState(() => ClockStore.worldCities.remove(city.name));
                ClockStore.saveCities();
              },
              icon: const Icon(
                Icons.close,
                size: 18,
                color: ClockTheme.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.public_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _openAddCity() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(sheetContext).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'إضافة مدينة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ...worldCitiesData.map((c) {
              final added = ClockStore.worldCities.contains(c.name);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ClockTheme.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    c.icon,
                    color: ClockTheme.cyan,
                    size: 22,
                  ),
                ),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(c.country),
                trailing: added
                    ? const Icon(
                        Icons.check_circle,
                        color: ClockTheme.green,
                      )
                    : const Icon(Icons.add_circle_outline),
                onTap: () {
                  setState(() {
                    if (added) {
                      ClockStore.worldCities.remove(c.name);
                    } else {
                      ClockStore.worldCities.add(c.name);
                    }
                  });
                  ClockStore.saveCities();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ToolsSheet extends StatelessWidget {
  const ToolsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      _Tool(
        icon: Icons.alarm_outlined,
        title: 'Clock',
        color: ClockTheme.orange,
        builder: (_) => const AlarmTool(),
      ),
      _Tool(
        icon: Icons.calendar_month_outlined,
        title: 'Clock',
        color: ClockTheme.cyan,
        builder: (_) => const CalendarTool(),
      ),
      _Tool(
        icon: Icons.cake_outlined,
        title: 'Clock',
        color: ClockTheme.purple,
        builder: (_) => const AgeTool(),
      ),
      _Tool(
        icon: Icons.local_fire_department_outlined,
        title: 'Clock',
        color: ClockTheme.red,
        builder: (_) => const PomodoroTool(),
      ),
      _Tool(
        icon: Icons.compare_arrows,
        title: 'Clock',
        color: ClockTheme.green,
        builder: (_) => const ConverterTool(),
      ),
      _Tool(
        icon: Icons.event_outlined,
        title: 'Clock',
        color: ClockTheme.cyan,
        builder: (_) => const CountdownTool(),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'الأدوات',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemBuilder: (_, i) {
              final t = tools[i];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: t.builder),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: t.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(t.icon, color: t.color, size: 22),
                      ),
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tool {
  _Tool({
    required this.icon,
    required this.title,
    required this.color,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final Color color;
  final WidgetBuilder builder;
}

class AlarmTool extends StatefulWidget {
  const AlarmTool({super.key});

  @override
  State<AlarmTool> createState() => _AlarmToolState();
}

class _AlarmToolState extends State<AlarmTool> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المنبه')),
      body: ClockStore.alarms.isEmpty
          ? _empty()
          : ListView(
              padding: const EdgeInsets.all(18),
              children: ClockStore.alarms
                  .map(
                    (a) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                if (a.label.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    a.label,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: a.enabled,
                            onChanged: (v) {
                              setState(() => a.enabled = v);
                              ClockStore.saveAlarms();
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                ClockStore.alarms.remove(a);
                              });
                              ClockStore.saveAlarms();
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: ClockTheme.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlarm,
        icon: const Icon(Icons.add),
        label: const Text('إضافة منبه'),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_outlined,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'لا توجد منبهات',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addAlarm() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (time == null) return;

    final controller = TextEditingController();
    if (!mounted) return;
    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('اسم المنبه'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'اختياري',
            labelText: 'الاسم',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (label == null) return;

    setState(() {
      ClockStore.alarms.add(
        Alarm(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          hour: time.hour,
          minute: time.minute,
          label: label,
        ),
      );
    });
    ClockStore.saveAlarms();
  }
}

class CalendarTool extends StatefulWidget {
  const CalendarTool({super.key});

  @override
  State<CalendarTool> createState() => _CalendarToolState();
}

class _CalendarToolState extends State<CalendarTool> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday % 7;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('التقويم')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month - 1);
                      }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    Text(
                      '${_monthAr(_month.month)} ${_month.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _month = DateTime(_month.year, _month.month + 1);
                      }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (int i = 0; i < offset; i++)
                      const SizedBox(),
                    for (int d = 1; d <= days; d++)
                      _dayCell(d, today),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(int day, DateTime today) {
    final isToday = day == today.day &&
        _month.month == today.month &&
        _month.year == today.year;
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isToday ? ClockTheme.cyan : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            color: isToday ? Colors.white : null,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _monthAr(int m) => const [
        '',
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ][m];
}

class AgeTool extends StatefulWidget {
  const AgeTool({super.key});

  @override
  State<AgeTool> createState() => _AgeToolState();
}

class _AgeToolState extends State<AgeTool> {
  DateTime? _birth;

  void _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة العمر')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: ClockTheme.cyanGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.cake_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تاريخ ميلادك',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _birth == null
                              ? 'اضغط للاختيار'
                              : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left),
                ],
              ),
            ),
          ),
          if (_birth != null) ...[
            const SizedBox(height: 24),
            _result(),
          ],
        ],
      ),
    );
  }

  Widget _result() {
    final now = DateTime.now();
    final b = _birth!;
    int years = now.year - b.year;
    int months = now.month - b.month;
    int days = now.day - b.day;

    if (days < 0) {
      months--;
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    final totalDays = now.difference(b).inDays;
    final totalHours = totalDays * 24;
    final totalMinutes = totalHours * 60;

    final next = DateTime(now.year, b.month, b.day);
    final nextBirthday = next.isBefore(now)
        ? DateTime(now.year + 1, b.month, b.day)
        : next;
    final daysToNext = nextBirthday.difference(now).inDays;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: ClockTheme.cyanGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Text(
                'عمرك',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                '$years سنة، $months شهر، $days يوم',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _statRow('إجمالي الأيام', '$totalDays'),
        _statRow('إجمالي الساعات', '$totalHours'),
        _statRow('إجمالي الدقائق', '$totalMinutes'),
        _statRow(
          'عيد ميلادك القادم بعد',
          '$daysToNext يوم',
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class PomodoroTool extends StatefulWidget {
  const PomodoroTool({super.key});

  @override
  State<PomodoroTool> createState() => _PomodoroToolState();
}

class _PomodoroToolState extends State<PomodoroTool> {
  final int _workMinutes = 25;
  final int _breakMinutes = 5;
  int _remaining = 25 * 60;
  bool _isWork = true;
  bool _running = false;
  int _completed = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _ticker?.cancel();
      setState(() => _running = false);
    } else {
      setState(() => _running = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining--;
          if (_remaining <= 0) {
            _switchPhase();
          }
        });
      });
    }
  }

  void _switchPhase() {
    _ticker?.cancel();
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    setState(() {
      if (_isWork) {
        _completed++;
        _isWork = false;
        _remaining = _breakMinutes * 60;
      } else {
        _isWork = true;
        _remaining = _workMinutes * 60;
      }
      _running = false;
    });
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _running = false;
      _isWork = true;
      _remaining = _workMinutes * 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _isWork ? _workMinutes * 60 : _breakMinutes * 60;
    final progress = total == 0 ? 0.0 : _remaining / total;

    return Scaffold(
      appBar: AppBar(title: const Text('بومودورو')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: (_isWork ? ClockTheme.red : ClockTheme.green)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isWork ? 'وقت العمل' : 'وقت الراحة',
                style: TextStyle(
                  color: _isWork ? ClockTheme.red : ClockTheme.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(240, 240),
                    painter: _ProgressRingPainter(
                      progress: progress,
                      color: _isWork ? ClockTheme.red : ClockTheme.green,
                      trackColor: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.1),
                      strokeWidth: 10,
                    ),
                  ),
                  Text(
                    '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btn(
                _running ? Icons.pause : Icons.play_arrow,
                _running ? ClockTheme.orange : ClockTheme.green,
                _toggle,
              ),
              const SizedBox(width: 20),
              _btn(Icons.refresh, ClockTheme.red, _reset),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الجلسات المكتملة',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '$_completed',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: ClockTheme.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}

class ConverterTool extends StatefulWidget {
  const ConverterTool({super.key});

  @override
  State<ConverterTool> createState() => _ConverterToolState();
}

class _ConverterToolState extends State<ConverterTool> {
  WorldCity _from = worldCitiesData[0];
  WorldCity _to = worldCitiesData[3];
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final converted =
        _date.add(Duration(hours: _to.offsetHours - _from.offsetHours));

    return Scaffold(
      appBar: AppBar(title: const Text('محوّل التوقيت')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _cityPicker('من', _from, (c) => setState(() => _from = c)),
          const SizedBox(height: 16),
          _cityPicker('إلى', _to, (c) => setState(() => _to = c)),
          const SizedBox(height: 24),
          _dateTimeCard(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ClockTheme.cyanGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Text(
                  'التوقيت في المدينة الأخرى',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  '${converted.hour.toString().padLeft(2, '0')}:${converted.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '${_to.name} • ${converted.day}/${converted.month}/${converted.year}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityPicker(
    String label,
    WorldCity current,
    ValueChanged<WorldCity> onSelect,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<WorldCity>(
              value: current,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: worldCitiesData
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onSelect(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التاريخ والوقت',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) {
                      setState(() {
                        _date = DateTime(
                          d.year,
                          d.month,
                          d.day,
                          _date.hour,
                          _date.minute,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_date.day}/${_date.month}/${_date.year}',
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_date),
                    );
                    if (t != null) {
                      setState(() {
                        _date = DateTime(
                          _date.year,
                          _date.month,
                          _date.day,
                          t.hour,
                          t.minute,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CountdownTool extends StatefulWidget {
  const CountdownTool({super.key});

  @override
  State<CountdownTool> createState() => _CountdownToolState();
}

class _CountdownToolState extends State<CountdownTool> {
  DateTime _target = DateTime.now().add(const Duration(days: 30));
  String _name = 'حدث مهم';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = _target.difference(now);
    final isPast = diff.isNegative;

    final days = diff.inDays.abs();
    final hours = (diff.inHours % 24).abs();
    final minutes = (diff.inMinutes % 60).abs();
    final seconds = (diff.inSeconds % 60).abs();

    return Scaffold(
      appBar: AppBar(title: const Text('العد التنازلي')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _name = v),
                  decoration: const InputDecoration(
                    labelText: 'اسم الحدث',
                    hintText: 'مثال: عيد ميلادي',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _target,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2050),
                      );
                      if (d != null) setState(() => _target = d);
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_target.day}/${_target.month}/${_target.year}',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: ClockTheme.cyanGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  _name.isEmpty ? 'حدث مهم' : _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPast ? 'مضى على الحدث' : 'متبقٍ للحدث',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _unit('$days', 'يوم'),
                    _unit('$hours', 'ساعة'),
                    _unit('$minutes', 'دقيقة'),
                    _unit('$seconds', 'ثانية'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}