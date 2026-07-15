package com.example.ferfit_flutter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class FerFitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.ferfit_widget).apply {
                val streak = widgetData.getInt("streak", 0)
                val level = widgetData.getInt("level", 1)
                
                setTextViewText(R.id.widget_streak, "Racha: $streak \uD83D\uDD25")
                setTextViewText(R.id.widget_level, "Nivel: $level")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
