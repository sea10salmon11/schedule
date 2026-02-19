import 'package:flutter/material.dart';
import '../models/lesson.dart';

class LessonFormScreen extends StatefulWidget {
  final Lesson? lesson;
  final int dayOfWeek;

  const LessonFormScreen({
    super.key,
    this.lesson,
    required this.dayOfWeek,
  });

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    if (lesson != null) {
      _subjectCtrl.text = lesson.subject;
      _teacherCtrl.text = lesson.teacher;
      _roomCtrl.text = lesson.room;
      _startTime = TimeOfDay(hour: lesson.startHour, minute: lesson.startMinute);
      _endTime = TimeOfDay(hour: lesson.endHour, minute: lesson.endMinute);
    } else {
      _startTime = const TimeOfDay(hour: 8, minute: 0);
      _endTime = const TimeOfDay(hour: 8, minute: 45);
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _teacherCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Новый урок' : 'Изменить урок'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _subjectCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Предмет *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Введите название предмета' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teacherCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Учитель',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roomCtrl,
              decoration: const InputDecoration(
                labelText: 'Кабинет',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Начало',
                    time: _startTime,
                    onChanged: (t) => setState(() => _startTime = t),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label: 'Конец',
                    time: _endTime,
                    onChanged: (t) => setState(() => _endTime = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = Lesson(
      id: widget.lesson?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      subject: _subjectCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      room: _roomCtrl.text.trim(),
      startHour: _startTime.hour,
      startMinute: _startTime.minute,
      endHour: _endTime.hour,
      endMinute: _endTime.minute,
      dayOfWeek: widget.dayOfWeek,
    );

    Navigator.pop(context, result);
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final result = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (result != null) onChanged(result);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(time.format(context)),
      ),
    );
  }
}
