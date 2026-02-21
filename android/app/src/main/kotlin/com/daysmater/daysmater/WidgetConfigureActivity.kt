package com.daysmater.daysmater

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ArrayAdapter
import android.widget.ListView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class WidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 默认结果为取消
        setResult(RESULT_CANCELED)

        // 获取 widget ID
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        // 读取事件列表
        val prefs = HomeWidgetPlugin.getData(this)
        val allEventsJson = prefs.getString("all_events", null)

        if (allEventsJson == null) {
            showNoEvents()
            return
        }

        try {
            val events = JSONArray(allEventsJson)
            if (events.length() == 0) {
                showNoEvents()
                return
            }
            showEventList(events)
        } catch (e: Exception) {
            showNoEvents()
        }
    }

    private fun showNoEvents() {
        val textView = TextView(this).apply {
            text = getString(R.string.widget_no_events)
            textSize = 16f
            setPadding(48, 48, 48, 48)
        }
        setContentView(textView)
    }

    private fun showEventList(events: JSONArray) {
        val listView = ListView(this).apply {
            setPadding(0, 24, 0, 0)
        }

        val names = mutableListOf<String>()
        val ids = mutableListOf<Int>()

        for (i in 0 until events.length()) {
            val obj = events.getJSONObject(i)
            val name = obj.getString("name")
            val days = obj.getInt("days")
            val suffix = when {
                days == 0 -> "今天"
                days > 0 -> "还有${days}天"
                else -> "已过${-days}天"
            }
            names.add("$name ($suffix)")
            ids.add(obj.getInt("id"))
        }

        val adapter = ArrayAdapter(
            this,
            android.R.layout.simple_list_item_1,
            names
        )
        listView.adapter = adapter

        // 添加标题
        val header = TextView(this).apply {
            text = getString(R.string.widget_configure_title)
            textSize = 20f
            setPadding(48, 48, 48, 24)
        }
        listView.addHeaderView(header, null, false)

        listView.setOnItemClickListener { _, _, position, _ ->
            // 减去 header 的偏移
            val index = position - 1
            if (index < 0 || index >= ids.size) return@setOnItemClickListener

            val selectedId = ids[index]

            // 保存配置
            val widgetPrefs = getSharedPreferences(
                "widget_config", MODE_PRIVATE
            )
            widgetPrefs.edit()
                .putInt("widget_event_$appWidgetId", selectedId)
                .apply()

            // 立即更新小组件
            val appWidgetManager = AppWidgetManager.getInstance(this)
            CountdownWidgetProvider.updateAppWidget(
                this, appWidgetManager, appWidgetId
            )

            // 返回成功结果
            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }

        setContentView(listView)
    }
}
