package com.schedule.lessons;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;

public class ScheduleWidget extends AppWidgetProvider {
    private static final String PREFS_NAME = "SchedulePrefs";
    private static final String KEY_SCHEDULE = "schedule";
    
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.schedule_widget);
        
        // Получаем текущий день недели
        Calendar calendar = Calendar.getInstance();
        int dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK);
        int currentDay = dayOfWeek == Calendar.SUNDAY ? 5 : dayOfWeek - 2;
        if (currentDay < 0 || currentDay > 5) currentDay = 0;
        
        String[] days = {"Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"};
        String dayName = days[currentDay];
        
        // Получаем текущее время
        SimpleDateFormat timeFormat = new SimpleDateFormat("HH:mm", Locale.getDefault());
        String currentTime = timeFormat.format(calendar.getTime());
        
        // Загружаем расписание
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        String scheduleJson = prefs.getString(KEY_SCHEDULE, "{}");
        
        String widgetText = "Расписание на " + dayName;
        String nextLessonText = "";
        
        try {
            JSONObject schedule = new JSONObject(scheduleJson);
            JSONArray lessons = schedule.optJSONArray(dayName);
            
            if (lessons != null && lessons.length() > 0) {
                // Ищем следующий урок
                JSONObject nextLesson = null;
                for (int i = 0; i < lessons.length(); i++) {
                    JSONObject lesson = lessons.getJSONObject(i);
                    String lessonTime = lesson.getString("time");
                    
                    if (lessonTime.compareTo(currentTime) > 0) {
                        nextLesson = lesson;
                        break;
                    }
                }
                
                if (nextLesson != null) {
                    nextLessonText = "⏰ " + nextLesson.getString("time") + "\n" +
                                   "📚 " + nextLesson.getString("subject");
                    
                    if (nextLesson.has("teacher") && !nextLesson.getString("teacher").isEmpty()) {
                        nextLessonText += "\n👨‍🏫 " + nextLesson.getString("teacher");
                    }
                    
                    if (nextLesson.has("room") && !nextLesson.getString("room").isEmpty()) {
                        nextLessonText += "\n🚪 Каб. " + nextLesson.getString("room");
                    }
                } else {
                    // Все уроки прошли
                    nextLessonText = "✅ Все уроки на сегодня завершены";
                }
            } else {
                nextLessonText = "Нет уроков на сегодня";
            }
        } catch (JSONException e) {
            e.printStackTrace();
            nextLessonText = "Ошибка загрузки расписания";
        }
        
        views.setTextViewText(R.id.widget_title, widgetText);
        views.setTextViewText(R.id.widget_lesson, nextLessonText);
        
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }
}
