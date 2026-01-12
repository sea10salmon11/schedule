package com.schedule.lessons;

import android.app.Activity;
import android.appwidget.AppWidgetManager;
import android.content.ComponentName;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

public class MainActivity extends Activity {
    private static final String PREFS_NAME = "SchedulePrefs";
    private static final String KEY_SCHEDULE = "schedule";
    
    private LinearLayout scheduleContainer;
    private int currentDay = 0;
    private String[] days = {"Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"};
    private Button[] dayButtons;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Определяем текущий день недели
        Calendar calendar = Calendar.getInstance();
        int dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK);
        currentDay = dayOfWeek == Calendar.SUNDAY ? 5 : dayOfWeek - 2;
        if (currentDay < 0) currentDay = 0;
        
        createUI();
        loadSchedule();
    }
    
    private void createUI() {
        LinearLayout mainLayout = new LinearLayout(this);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setBackgroundColor(0xFFEEEEEE);
        mainLayout.setPadding(0, 0, 0, 0);
        
        // Заголовок
        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.VERTICAL);
        header.setBackgroundColor(0xFF5A67D8);
        header.setPadding(40, 60, 40, 40);
        
        TextView title = new TextView(this);
        title.setText("📚 Расписание уроков");
        title.setTextColor(0xFFFFFFFF);
        title.setTextSize(24);
        title.setPadding(0, 0, 0, 30);
        header.addView(title);
        
        // Кнопки дней недели
        ScrollView daysScroll = new ScrollView(this);
        LinearLayout daysLayout = new LinearLayout(this);
        daysLayout.setOrientation(LinearLayout.HORIZONTAL);
        dayButtons = new Button[days.length];
        
        for (int i = 0; i < days.length; i++) {
            final int dayIndex = i;
            Button dayBtn = new Button(this);
            dayBtn.setText(days[i]);
            dayBtn.setPadding(30, 20, 30, 20);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            );
            params.setMargins(0, 0, 20, 0);
            dayBtn.setLayoutParams(params);
            dayBtn.setOnClickListener(v -> selectDay(dayIndex));
            daysLayout.addView(dayBtn);
            dayButtons[i] = dayBtn;
        }
        
        daysScroll.addView(daysLayout);
        header.addView(daysScroll);
        mainLayout.addView(header);
        
        // Контейнер для расписания
        ScrollView scrollView = new ScrollView(this);
        scheduleContainer = new LinearLayout(this);
        scheduleContainer.setOrientation(LinearLayout.VERTICAL);
        scheduleContainer.setPadding(40, 40, 40, 40);
        scrollView.addView(scheduleContainer);
        
        LinearLayout.LayoutParams scrollParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            0,
            1.0f
        );
        scrollView.setLayoutParams(scrollParams);
        mainLayout.addView(scrollView);
        
        // Кнопка добавления урока
        Button addButton = new Button(this);
        addButton.setText("+ Добавить урок");
        addButton.setBackgroundColor(0xFF5A67D8);
        addButton.setTextColor(0xFFFFFFFF);
        addButton.setTextSize(18);
        addButton.setPadding(40, 40, 40, 40);
        addButton.setOnClickListener(v -> showAddLessonDialog());
        mainLayout.addView(addButton);
        
        setContentView(mainLayout);
        updateDayButtons();
    }
    
    private void selectDay(int day) {
        currentDay = day;
        updateDayButtons();
        loadSchedule();
    }
    
    private void updateDayButtons() {
        for (int i = 0; i < dayButtons.length; i++) {
            if (i == currentDay) {
                dayButtons[i].setBackgroundColor(0xFFFFFFFF);
                dayButtons[i].setTextColor(0xFF5A67D8);
            } else {
                dayButtons[i].setBackgroundColor(0xFF667EEA);
                dayButtons[i].setTextColor(0xFFFFFFFF);
            }
        }
    }
    
    private void loadSchedule() {
        scheduleContainer.removeAllViews();
        
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        String scheduleJson = prefs.getString(KEY_SCHEDULE, "{}");
        
        try {
            JSONObject schedule = new JSONObject(scheduleJson);
            JSONArray lessons = schedule.optJSONArray(days[currentDay]);
            
            if (lessons == null || lessons.length() == 0) {
                TextView emptyText = new TextView(this);
                emptyText.setText("Уроков на " + days[currentDay].toLowerCase() + " нет");
                emptyText.setTextSize(16);
                emptyText.setTextColor(0xFF666666);
                emptyText.setPadding(0, 100, 0, 0);
                scheduleContainer.addView(emptyText);
            } else {
                for (int i = 0; i < lessons.length(); i++) {
                    JSONObject lesson = lessons.getJSONObject(i);
                    addLessonCard(lesson, i);
                }
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        
        updateWidget();
    }
    
    private void addLessonCard(JSONObject lesson, int index) throws JSONException {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        card.setBackgroundColor(0xFFFFFFFF);
        card.setPadding(40, 40, 40, 40);
        LinearLayout.LayoutParams cardParams = new LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        );
        cardParams.setMargins(0, 0, 0, 30);
        card.setLayoutParams(cardParams);
        
        // Время
        TextView timeText = new TextView(this);
        timeText.setText("🕐 " + lesson.getString("time"));
        timeText.setTextSize(18);
        timeText.setTextColor(0xFF5A67D8);
        timeText.setPadding(0, 0, 0, 20);
        card.addView(timeText);
        
        // Предмет
        TextView subjectText = new TextView(this);
        subjectText.setText(lesson.getString("subject"));
        subjectText.setTextSize(20);
        subjectText.setTextColor(0xFF2D3748);
        subjectText.setPadding(0, 0, 0, 10);
        card.addView(subjectText);
        
        // Учитель
        if (lesson.has("teacher") && !lesson.getString("teacher").isEmpty()) {
            TextView teacherText = new TextView(this);
            teacherText.setText("👨‍🏫 " + lesson.getString("teacher"));
            teacherText.setTextSize(14);
            teacherText.setTextColor(0xFF718096);
            card.addView(teacherText);
        }
        
        // Кабинет
        if (lesson.has("room") && !lesson.getString("room").isEmpty()) {
            TextView roomText = new TextView(this);
            roomText.setText("🚪 Кабинет " + lesson.getString("room"));
            roomText.setTextSize(14);
            roomText.setTextColor(0xFF718096);
            card.addView(roomText);
        }
        
        // Кнопки
        LinearLayout buttonsLayout = new LinearLayout(this);
        buttonsLayout.setOrientation(LinearLayout.HORIZONTAL);
        buttonsLayout.setPadding(0, 30, 0, 0);
        
        Button deleteBtn = new Button(this);
        deleteBtn.setText("🗑️ Удалить");
        deleteBtn.setBackgroundColor(0xFFFFEBEE);
        deleteBtn.setTextColor(0xFFD32F2F);
        final int lessonIndex = index;
        deleteBtn.setOnClickListener(v -> deleteLesson(lessonIndex));
        buttonsLayout.addView(deleteBtn);
        
        card.addView(buttonsLayout);
        scheduleContainer.addView(card);
    }
    
    private void showAddLessonDialog() {
        LinearLayout dialogLayout = new LinearLayout(this);
        dialogLayout.setOrientation(LinearLayout.VERTICAL);
        dialogLayout.setPadding(60, 60, 60, 60);
        dialogLayout.setBackgroundColor(0xFFFFFFFF);
        
        TextView dialogTitle = new TextView(this);
        dialogTitle.setText("Новый урок");
        dialogTitle.setTextSize(20);
        dialogTitle.setPadding(0, 0, 0, 40);
        dialogLayout.addView(dialogTitle);
        
        // Поле предмета
        TextView subjectLabel = new TextView(this);
        subjectLabel.setText("Предмет:");
        dialogLayout.addView(subjectLabel);
        
        EditText subjectInput = new EditText(this);
        subjectInput.setHint("Математика");
        dialogLayout.addView(subjectInput);
        
        // Поле времени
        TextView timeLabel = new TextView(this);
        timeLabel.setText("Время (например, 09:00):");
        timeLabel.setPadding(0, 30, 0, 0);
        dialogLayout.addView(timeLabel);
        
        EditText timeInput = new EditText(this);
        timeInput.setHint("09:00");
        dialogLayout.addView(timeInput);
        
        // Поле учителя
        TextView teacherLabel = new TextView(this);
        teacherLabel.setText("Учитель (необязательно):");
        teacherLabel.setPadding(0, 30, 0, 0);
        dialogLayout.addView(teacherLabel);
        
        EditText teacherInput = new EditText(this);
        teacherInput.setHint("Иванова А.П.");
        dialogLayout.addView(teacherInput);
        
        // Поле кабинета
        TextView roomLabel = new TextView(this);
        roomLabel.setText("Кабинет (необязательно):");
        roomLabel.setPadding(0, 30, 0, 0);
        dialogLayout.addView(roomLabel);
        
        EditText roomInput = new EditText(this);
        roomInput.setHint("301");
        dialogLayout.addView(roomInput);
        
        // Кнопки
        LinearLayout buttonsLayout = new LinearLayout(this);
        buttonsLayout.setOrientation(LinearLayout.HORIZONTAL);
        buttonsLayout.setPadding(0, 40, 0, 0);
        
        Button saveBtn = new Button(this);
        saveBtn.setText("Сохранить");
        saveBtn.setBackgroundColor(0xFF5A67D8);
        saveBtn.setTextColor(0xFFFFFFFF);
        saveBtn.setOnClickListener(v -> {
            String subject = subjectInput.getText().toString().trim();
            String time = timeInput.getText().toString().trim();
            String teacher = teacherInput.getText().toString().trim();
            String room = roomInput.getText().toString().trim();
            
            if (subject.isEmpty() || time.isEmpty()) {
                Toast.makeText(this, "Заполните предмет и время", Toast.LENGTH_SHORT).show();
                return;
            }
            
            saveLesson(subject, time, teacher, room);
            setContentView(new LinearLayout(this));
            createUI();
            loadSchedule();
        });
        
        Button cancelBtn = new Button(this);
        cancelBtn.setText("Отмена");
        cancelBtn.setBackgroundColor(0xFFE2E8F0);
        cancelBtn.setTextColor(0xFF4A5568);
        cancelBtn.setOnClickListener(v -> {
            setContentView(new LinearLayout(this));
            createUI();
            loadSchedule();
        });
        
        buttonsLayout.addView(saveBtn);
        buttonsLayout.addView(cancelBtn);
        dialogLayout.addView(buttonsLayout);
        
        ScrollView scrollView = new ScrollView(this);
        scrollView.addView(dialogLayout);
        setContentView(scrollView);
    }
    
    private void saveLesson(String subject, String time, String teacher, String room) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        String scheduleJson = prefs.getString(KEY_SCHEDULE, "{}");
        
        try {
            JSONObject schedule = new JSONObject(scheduleJson);
            JSONArray lessons = schedule.optJSONArray(days[currentDay]);
            if (lessons == null) {
                lessons = new JSONArray();
            }
            
            JSONObject newLesson = new JSONObject();
            newLesson.put("subject", subject);
            newLesson.put("time", time);
            newLesson.put("teacher", teacher);
            newLesson.put("room", room);
            
            lessons.put(newLesson);
            schedule.put(days[currentDay], lessons);
            
            prefs.edit().putString(KEY_SCHEDULE, schedule.toString()).apply();
            Toast.makeText(this, "Урок добавлен", Toast.LENGTH_SHORT).show();
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    
    private void deleteLesson(int index) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        String scheduleJson = prefs.getString(KEY_SCHEDULE, "{}");
        
        try {
            JSONObject schedule = new JSONObject(scheduleJson);
            JSONArray lessons = schedule.optJSONArray(days[currentDay]);
            if (lessons != null && index < lessons.length()) {
                JSONArray newLessons = new JSONArray();
                for (int i = 0; i < lessons.length(); i++) {
                    if (i != index) {
                        newLessons.put(lessons.getJSONObject(i));
                    }
                }
                schedule.put(days[currentDay], newLessons);
                prefs.edit().putString(KEY_SCHEDULE, schedule.toString()).apply();
                loadSchedule();
                Toast.makeText(this, "Урок удален", Toast.LENGTH_SHORT).show();
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }
    
    private void updateWidget() {
        Intent intent = new Intent(this, ScheduleWidget.class);
        intent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE);
        int[] ids = AppWidgetManager.getInstance(getApplication())
            .getAppWidgetIds(new ComponentName(getApplication(), ScheduleWidget.class));
        intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids);
        sendBroadcast(intent);
    }
}
