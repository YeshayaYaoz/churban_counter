package com.example.churban_counter

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONObject

/**
 * Android AppWidget provider for the Churban counter.
 *
 * Reads data saved by the Flutter side via HomeWidget and
 * updates the native RemoteViews layout. The saved data covers the
 * upcoming days, so an alarm at midnight is all it takes to advance
 * the widget while the app is closed.
 */
class ChurbanWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action in REFRESH_ACTIONS) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ChurbanWidgetProvider::class.java)
            )
            if (appWidgetIds.isNotEmpty()) {
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val day = readToday(context)
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, day)
        }
        scheduleNextDay(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        // The widget was resized, so its contents need to fit the new size
        updateAppWidget(context, appWidgetManager, appWidgetId, readToday(context))
    }

    override fun onDisabled(context: Context) {
        // The last widget was removed, so there is nothing left to advance
        alarmManager(context).cancel(nextDayIntent(context))
    }

    private class WidgetDay(
        val totalDays: String,
        val yearsMonths: String,
        val hebrewDate: String,
        val isTishaBAv: Boolean
    )

    companion object {
        private const val ACTION_NEXT_DAY = "com.example.churban_counter.NEXT_DAY"

        // A change to the clock or time zone moves the next midnight, and
        // can leave the widget showing the wrong day until then
        private val REFRESH_ACTIONS = setOf(
            ACTION_NEXT_DAY,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED
        )

        // The shortest window Android allows without the exact alarm permission
        private const val ALARM_WINDOW_MILLIS = 10 * 60 * 1000L

        // From this height there is room for the date, divider and Tisha B'Av title
        private const val TALL_HEIGHT_DP = 150

        // Space taken up by everything except the number, in dp
        private const val SIDE_PADDING_DP = 32
        private const val SHORT_LINES_DP = 92
        private const val TALL_LINES_DP = 128

        // Size of "714,502" relative to its font size
        private const val NUMBER_WIDTH_EM = 3.8f
        private const val NUMBER_HEIGHT_EM = 1.2f

        private fun numberSizeDp(width: Int, height: Int, linesHeight: Int): Float {
            val fitWidth = (width - SIDE_PADDING_DP) / NUMBER_WIDTH_EM
            val fitHeight = (height - linesHeight) / NUMBER_HEIGHT_EM
            return minOf(fitWidth, fitHeight).coerceIn(24f, 52f)
        }

        private fun visibleIf(condition: Boolean) = if (condition) View.VISIBLE else View.GONE

        private fun alarmManager(context: Context) =
            context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        private fun nextDayIntent(context: Context): PendingIntent {
            val intent = Intent(context, ChurbanWidgetProvider::class.java)
                .setAction(ACTION_NEXT_DAY)
            return PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun scheduleNextDay(context: Context) {
            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            // Not a wakeup alarm: while the device sleeps nobody sees the
            // widget, so it can wait until the device next wakes up
            alarmManager(context).setWindow(
                AlarmManager.RTC,
                midnight.timeInMillis,
                ALARM_WINDOW_MILLIS,
                nextDayIntent(context)
            )
        }

        private fun readToday(context: Context): WidgetDay {
            // Read data saved by Flutter via home_widget
            val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)

            val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            val today = prefs.getString("upcoming_days", null)?.let {
                JSONObject(it).optJSONObject(todayKey)
            }

            // Past the end of the upcoming days, stay on what the app last saved
            fun value(key: String, fallback: String) =
                today?.optString(key)?.ifEmpty { null } ?: prefs.getString(key, fallback) ?: fallback

            return WidgetDay(
                totalDays = value("total_days", "---"),
                yearsMonths = value("years_months", ""),
                hebrewDate = value("hebrew_date", ""),
                isTishaBAv = value("is_tisha_bav", "false") == "true"
            )
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            day: WidgetDay
        ) {
            // The widget's size in portrait is its min width and max height,
            // and in landscape its max width and min height
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val portrait = buildViews(
                context,
                day,
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH),
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
            )
            val landscape = buildViews(
                context,
                day,
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH),
                options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            )

            appWidgetManager.updateAppWidget(appWidgetId, RemoteViews(landscape, portrait))
        }

        private fun buildViews(context: Context, day: WidgetDay, width: Int, height: Int): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.churban_widget)

            // Set the day count
            views.setTextViewText(R.id.tv_day_count, day.totalDays)

            // Set the years and months
            views.setTextViewText(R.id.tv_years_months, day.yearsMonths)
            views.setViewVisibility(R.id.tv_years_months, visibleIf(day.yearsMonths.isNotEmpty()))

            // Set the Hebrew date and fit the number to the widget's size
            val isTall = height >= TALL_HEIGHT_DP
            views.setTextViewText(R.id.tv_hebrew_date, day.hebrewDate)
            views.setViewVisibility(R.id.tv_hebrew_date, visibleIf(isTall))
            views.setViewVisibility(R.id.divider, visibleIf(isTall))
            if (width > 0 && height > 0) {
                views.setTextViewTextSize(
                    R.id.tv_day_count,
                    TypedValue.COMPLEX_UNIT_DIP,
                    numberSizeDp(width, height, if (isTall) TALL_LINES_DP else SHORT_LINES_DP)
                )
            }

            // On Tisha B'Av, show the title and change the accent color
            val accentColor = if (day.isTishaBAv) 0xFFE05555.toInt() else 0xFFD4A84B.toInt()
            views.setViewVisibility(R.id.tv_title, visibleIf(day.isTishaBAv && isTall))
            views.setTextColor(R.id.tv_days_label, accentColor)
            views.setTextColor(R.id.tv_caption, accentColor)

            return views
        }
    }
}
