package com.daysmater.daysmater

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlin.math.abs

class CountdownWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // 小组件首次添加时
    }

    override fun onDisabled(context: Context) {
        // 最后一个小组件移除时
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // 获取该小组件绑定的事件 ID
            val widgetPrefs = context.getSharedPreferences(
                "widget_config", Context.MODE_PRIVATE
            )
            val eventId = widgetPrefs.getInt("widget_event_$appWidgetId", -1)

            // 获取 HomeWidget 共享数据
            val prefs = HomeWidgetPlugin.getData(context)
            val eventName = prefs.getString("event_name", "倒数日") ?: "倒数日"
            val eventDays = prefs.getInt("event_days", 0)
            val eventDate = prefs.getString("event_date", "") ?: ""
            val eventLabel = prefs.getString("event_label", "还有") ?: "还有"
            val storedEventId = prefs.getInt("event_id", 0)

            // 如果该小组件配置了特定事件且与当前全局数据不同，
            // 使用 all_events JSON 数据查找对应事件
            var name = eventName
            var days = eventDays
            var date = eventDate
            var label = eventLabel
            var targetEventId = storedEventId

            if (eventId >= 0) {
                val allEventsJson = prefs.getString("all_events", null)
                if (allEventsJson != null) {
                    try {
                        val parsed = org.json.JSONArray(allEventsJson)
                        for (i in 0 until parsed.length()) {
                            val obj = parsed.getJSONObject(i)
                            if (obj.getInt("id") == eventId) {
                                name = obj.getString("name")
                                days = obj.getInt("days")
                                date = obj.getString("date")
                                targetEventId = eventId
                                label = when {
                                    days == 0 -> "就是今天"
                                    days > 0 -> "还有"
                                    else -> "已经"
                                }
                                break
                            }
                        }
                    } catch (e: Exception) {
                        // JSON 解析失败，使用默认值
                    }
                }
            }

            val views = RemoteViews(context.packageName, R.layout.countdown_widget)
            views.setTextViewText(R.id.widget_event_name, name)
            views.setTextViewText(R.id.widget_days, "${abs(days)}")
            views.setTextViewText(R.id.widget_date, date)
            views.setTextViewText(R.id.widget_label, label)

            if (days == 0) {
                views.setTextViewText(R.id.widget_days_unit, "")
            } else {
                views.setTextViewText(R.id.widget_days_unit, "天")
            }

            // 点击小组件打开 App
            val intent = context.packageManager.getLaunchIntentForPackage(
                context.packageName
            )
            if (intent != null) {
                intent.data = Uri.parse("daysmater://event/$targetEventId")
                val pendingIntent = PendingIntent.getActivity(
                    context, appWidgetId, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
