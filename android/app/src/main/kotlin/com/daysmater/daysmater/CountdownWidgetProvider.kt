package com.daysmater.daysmater

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class CountdownWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.countdown_widget)
            views.setTextViewText(R.id.widget_event_name, "玲华倒数")
            views.setTextViewText(R.id.widget_days, "0")
            views.setTextViewText(R.id.widget_days_unit, "天")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
