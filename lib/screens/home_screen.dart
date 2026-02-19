import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'lesson_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Lesson> _lessons = [];
  late TabController _tabController;
  bool _loading = true;

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final todayIndex = DateTime.now().weekday - 1; // 0-based
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: todayIndex,
    );
    _loadLessons();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateNotification();
    }
  }

  Future<void> _loadLessons() async {
    final lessons = await StorageService.loadLessons();
    if (!mounted) return;
    setState(() {
      _lessons = lessons;
      _loading = false;
    });
    await _updateNotification();
  }

  Future<void> _updateNotification() async {
    await NotificationService.showNextLesson(_findNextLesson());
  }

  /// Returns the next lesson that hasn't started yet, looking up to 7 days ahead.
  Lesson? _findNextLesson() {
    final now = DateTime.now();
    for (int d = 0; d < 7; d++) {
      final date = now.add(Duration(days: d));
      final weekday = date.weekday;
      final dayLessons = _sortedLessonsForDay(weekday);

      for (final lesson in dayLessons) {
        if (d == 0) {
          final startMin = lesson.startHour * 60 + lesson.startMinute;
          final nowMin = now.hour * 60 + now.minute;
          if (startMin > nowMin) return lesson;
        } else {
          return lesson;
        }
      }
    }
    return null;
  }

  List<Lesson> _sortedLessonsForDay(int dayOfWeek) {
    return _lessons
        .where((l) => l.dayOfWeek == dayOfWeek)
        .toList()
      ..sort((a, b) => (a.startHour * 60 + a.startMinute)
          .compareTo(b.startHour * 60 + b.startMinute));
  }

  Future<void> _addLesson() async {
    final dayOfWeek = _tabController.index + 1;
    final result = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonFormScreen(dayOfWeek: dayOfWeek),
      ),
    );
    if (result != null) {
      setState(() => _lessons.add(result));
      await StorageService.saveLessons(_lessons);
      await _updateNotification();
    }
  }

  Future<void> _editLesson(Lesson lesson) async {
    final result = await Navigator.push<Lesson>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LessonFormScreen(lesson: lesson, dayOfWeek: lesson.dayOfWeek),
      ),
    );
    if (result != null) {
      setState(() {
        final idx = _lessons.indexWhere((l) => l.id == lesson.id);
        if (idx != -1) _lessons[idx] = result;
      });
      await StorageService.saveLessons(_lessons);
      await _updateNotification();
    }
  }

  Future<void> _deleteLesson(Lesson lesson) async {
    setState(() => _lessons.removeWhere((l) => l.id == lesson.id));
    await StorageService.saveLessons(_lessons);
    await _updateNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Расписание',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: _dayNames.map((d) => Tab(text: d)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(7, (i) {
                final dayOfWeek = i + 1;
                final dayLessons = _sortedLessonsForDay(dayOfWeek);
                final nextLesson = _findNextLesson();

                if (dayLessons.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 48,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Нет уроков',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Нажмите + чтобы добавить',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: dayLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = dayLessons[index];
                    final isNext = nextLesson?.id == lesson.id;
                    return _LessonCard(
                      lesson: lesson,
                      isNext: isNext,
                      onTap: () => _editLesson(lesson),
                      onDismissed: () => _deleteLesson(lesson),
                    );
                  },
                );
              }),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLesson,
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        tooltip: 'Добавить урок',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isNext;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  static const _palette = [
    Color(0xFF6C63FF), // violet
    Color(0xFF10B981), // emerald
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // coral
    Color(0xFF8B5CF6), // purple
    Color(0xFF06B6D4), // cyan
    Color(0xFFEC4899), // pink
    Color(0xFF059669), // green
  ];

  const _LessonCard({
    required this.lesson,
    required this.isNext,
    required this.onTap,
    required this.onDismissed,
  });

  Color get _color => _palette[lesson.subject.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Dismissible(
      key: Key(lesson.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isNext
                  ? color.withOpacity(0.22)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isNext ? 18 : 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: isNext
              ? Border.all(color: color.withOpacity(0.40), width: 1.5)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Colored left accent strip
                  Container(
                    width: 5,
                    color: color,
                  ),
                  const SizedBox(width: 14),
                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lesson.subject,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              if (isNext)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Следующий',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${lesson.startTimeStr} — ${lesson.endTimeStr}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (lesson.room.isNotEmpty ||
                                  lesson.teacher.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    '  ·  ${_details()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _details() {
    final parts = <String>[];
    if (lesson.room.isNotEmpty) parts.add('каб. ${lesson.room}');
    if (lesson.teacher.isNotEmpty) parts.add(lesson.teacher);
    return parts.join(' · ');
  }
}
