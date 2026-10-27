package com.wakeup.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AlarmWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.alarm_widget).apply {
                // Lấy dữ liệu từ Flutter qua widgetData (home_widget plugin tự xử lý)
                val nextAlarm = widgetData.getString("next_alarm", "Chưa đặt báo thức")
                setTextViewText(R.id.widget_title, nextAlarm)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
