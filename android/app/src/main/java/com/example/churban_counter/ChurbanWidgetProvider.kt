package com.example.churban_counter

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Android AppWidget provider for the Churban counter.
 *
 * Reads data saved by the Flutter side via HomeWidget and
 * updates the native RemoteViews layout.
 */
class ChurbanWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Read data saved by Flutter via home_widget
            val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)

            val totalDays = prefs.getString("total_days", "---") ?: "---"
            val hebrewDate = prefs.getString("hebrew_date", "") ?: ""
            val isTishaBAv = prefs.getString("is_tisha_bav", "false") == "true"

            val views = RemoteViews(context.packageName, R.layout.churban_widget)

            // Set the day count
            views.setTextViewText(R.id.tv_day_count, totalDays)

            // Set the Hebrew date
            views.setTextViewText(R.id.tv_hebrew_date, hebrewDate)

            // On Tisha B'Av, change the title text
            if (isTishaBAv) {
                views.setTextViewText(R.id.tv_title, "ט׳ באב")
                views.setTextColor(R.id.tv_title, 0xFFCC3333.toInt())
            } else {
                views.setTextViewText(R.id.tv_title, "זכר לחורבן")
                views.setTextColor(R.id.tv_title, 0xFFD4A84B.toInt())
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
