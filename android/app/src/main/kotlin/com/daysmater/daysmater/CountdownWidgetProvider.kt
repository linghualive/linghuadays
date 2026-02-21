package com.daysmater.daysmater

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.abs

class CountdownWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences? = null
        ) {
            // 获取 HomeWidget 共享数据
            val prefs = widgetData ?: context.getSharedPreferences(
                "HomeWidgetPreferences", Context.MODE_PRIVATE
            )

            // 获取该小组件绑定的事件 ID
            val widgetConfigPrefs = context.getSharedPreferences(
                "widget_config", Context.MODE_PRIVATE
            )
            val eventId = widgetConfigPrefs.getInt("widget_event_$appWidgetId", -1)

            val eventName = prefs.getString("event_name", null) ?: "倒数日"
            val eventDays = prefs.getInt("event_days", 0)
            val eventDate = prefs.getString("event_date", null) ?: ""
            val eventLabel = prefs.getString("event_label", null) ?: "还有"
            val storedEventId = prefs.getInt("event_id", 0)

            // 使用全局数据作为默认值
            var name = eventName
            var days = eventDays
            var date = eventDate
            var label = eventLabel
            var targetEventId = storedEventId

            // 如果该小组件配置了特定事件，从 all_events JSON 查找对应事件
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
            } else {
                // 未配置特定事件时，使用 all_events 中的第一个事件
                val allEventsJson = prefs.getString("all_events", null)
                if (allEventsJson != null) {
                    try {
                        val parsed = org.json.JSONArray(allEventsJson)
                        if (parsed.length() > 0) {
                            val obj = parsed.getJSONObject(0)
                            name = obj.getString("name")
                            days = obj.getInt("days")
                            date = obj.getString("date")
                            targetEventId = obj.getInt("id")
                            label = when {
                                days == 0 -> "就是今天"
                                days > 0 -> "还有"
                                else -> "已经"
                            }
                        }
                    } catch (e: Exception) {
                        // 使用默认值
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
