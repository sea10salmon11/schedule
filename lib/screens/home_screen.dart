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
    with SingleTickerProviderStateMixin {
  List<Lesson> _lessons = [];
  late TabController _tabController;
  bool _loading = true;

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
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
    _tabController.dispose();
    super.dispose();
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
          // Today: only include lessons that haven't started yet
          final startMin = lesson.startHour * 60 + lesson.startMinute;
          final nowMin = now.hour * 60 + now.minute;
          if (startMin > nowMin) return lesson;
        } else {
          // Future day: first lesson of that day
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
      appBar: AppBar(
        title: const Text('Расписание'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _dayNames.map((d) => Tab(text: d)).toList(),
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
                        Icon(Icons.event_available,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant),
                        const SizedBox(height: 12),
                        const Text('Уроков нет'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
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

  const _LessonCard({
    required this.lesson,
    required this.isNext,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(lesson.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        color: isNext ? colorScheme.primaryContainer : null,
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor:
                isNext ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            foregroundColor:
                isNext ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            child: Text(
              lesson.startTimeStr.substring(0, 2),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            lesson.subject,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            _buildSubtitle(),
            style: TextStyle(
              color: isNext
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: isNext
              ? Chip(
                  label: const Text('Следующий',
                      style: TextStyle(fontSize: 11)),
                  backgroundColor: colorScheme.primary,
                  labelStyle: TextStyle(color: colorScheme.onPrimary),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              : null,
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = ['${lesson.startTimeStr} — ${lesson.endTimeStr}'];
    if (lesson.room.isNotEmpty) parts.add('каб. ${lesson.room}');
    if (lesson.teacher.isNotEmpty) parts.add(lesson.teacher);
    return parts.join(' · ');
  }
}
