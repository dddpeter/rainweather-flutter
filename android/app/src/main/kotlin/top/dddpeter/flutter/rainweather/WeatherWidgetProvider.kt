package top.dddpeter.flutter.rainweather

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import org.json.JSONArray

class WeatherWidgetProvider : AppWidgetProvider() {
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
        // Widget首次添加到桌面时调用
    }

    override fun onDisabled(context: Context) {
        // Widget从桌面移除时调用
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.weather_widget)

            try {
                val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                
                // 读取数据，使用 flutter. 前缀（Flutter SharedPreferences 格式）
                val date = prefs.getString("flutter.date", null) ?: "加载中..."
                val weekday = prefs.getString("flutter.weekday", null) ?: ""
                val lunarDate = prefs.getString("flutter.lunar_date", null) ?: ""
                val time = prefs.getString("flutter.time", null) ?: "--:--"
                val weatherText = prefs.getString("flutter.weather_text", null) ?: "未知"
                val temperature = prefs.getString("flutter.temperature", null) ?: "--°"
                val location = prefs.getString("flutter.location", null) ?: "未知位置"
                val aqi = prefs.getString("flutter.aqi", null) ?: "--"
                val wind = prefs.getString("flutter.wind", null) ?: "--"
                val rainAlert = prefs.getString("flutter.rain_alert", null) ?: "暂无"

                // 更新第一行
                views.setTextViewText(R.id.text_date, date)
                views.setTextViewText(R.id.text_weekday, weekday)
                views.setTextViewText(R.id.text_lunar, lunarDate)

                // 更新第二行
                val isDaytime = isDaytime(time)
                val weatherIconRes = getWeatherIcon(weatherText, isDaytime)
                views.setImageViewResource(R.id.image_weather_icon, weatherIconRes)
                views.setTextViewText(R.id.text_temperature, temperature.replace("°", "℃"))
                views.setTextViewText(R.id.text_weather, weatherText)

                // 更新第三行
                views.setTextViewText(R.id.text_location, "📍 $location")
                views.setTextViewText(R.id.text_aqi, "空气 $aqi")
                views.setTextViewText(R.id.text_wind, wind)
                views.setTextViewText(R.id.text_rain, "💧$rainAlert")

                // 更新第四行（5日预报）
                val forecast5dJson = prefs.getString("flutter.forecast_5d", null) ?: "[]"
                updateForecast(views, forecast5dJson, isDaytime)

                // 点击打开应用
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            } catch (e: Exception) {
                e.printStackTrace()
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun updateForecast(views: RemoteViews, jsonStr: String, isDaytime: Boolean) {
            try {
                val jsonArray = JSONArray(jsonStr)
                
                data class ForecastIds(
                    val date: Int,
                    val weekday: Int,
                    val weather: Int,
                    val tempHigh: Int,
                    val tempLow: Int
                )
                
                val dayIds = listOf(
                    ForecastIds(R.id.forecast_day1_date, R.id.forecast_day1_weekday, R.id.forecast_day1_weather, R.id.forecast_day1_temp_high, R.id.forecast_day1_temp_low),
                    ForecastIds(R.id.forecast_day2_date, R.id.forecast_day2_weekday, R.id.forecast_day2_weather, R.id.forecast_day2_temp_high, R.id.forecast_day2_temp_low),
                    ForecastIds(R.id.forecast_day3_date, R.id.forecast_day3_weekday, R.id.forecast_day3_weather, R.id.forecast_day3_temp_high, R.id.forecast_day3_temp_low),
                    ForecastIds(R.id.forecast_day4_date, R.id.forecast_day4_weekday, R.id.forecast_day4_weather, R.id.forecast_day4_temp_high, R.id.forecast_day4_temp_low),
                    ForecastIds(R.id.forecast_day5_date, R.id.forecast_day5_weekday, R.id.forecast_day5_weather, R.id.forecast_day5_temp_high, R.id.forecast_day5_temp_low)
                )
                
                for (i in 0 until minOf(jsonArray.length(), 5)) {
                    val item = jsonArray.getJSONObject(i)
                    val date = item.optString("date", "")
                    val weekday = item.optString("weekday", "")
                    val weatherIconText = item.optString("weatherIcon", "")
                    val weatherIconRes = getWeatherIcon(weatherIconText, isDaytime)
                    val high = item.optString("tempHigh", "--").replace("°", "℃")
                    val low = item.optString("tempLow", "--").replace("°", "℃")
                    
                    // 分别设置日期和周几，格式：日期 周x
                    views.setTextViewText(dayIds[i].date, date)
                    views.setTextViewText(dayIds[i].weekday, if (weekday.isNotEmpty()) " $weekday" else "")
                    views.setImageViewResource(dayIds[i].weather, weatherIconRes)
                    views.setTextViewText(dayIds[i].tempHigh, high)
                    views.setTextViewText(dayIds[i].tempLow, low)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        /**
         * 判断是否为白天
         * 根据时间字符串判断，6:00-18:00为白天
         */
        private fun isDaytime(timeStr: String): Boolean {
            return try {
                val hour = timeStr.split(":")[0].toIntOrNull() ?: 12
                hour in 6..18
            } catch (e: Exception) {
                true // 默认白天
            }
        }
        
        /**
         * 根据天气文本和时间获取对应的图标资源
         */
        private fun getWeatherIcon(weatherText: String, isDaytime: Boolean): Int {
            // 白天图标映射
            val dayIconMap = mapOf(
                "晴" to R.drawable.q,
                "多云" to R.drawable.dy,
                "多云转晴" to R.drawable.dyq,
                "晴转多云" to R.drawable.dyq,
                "阴" to R.drawable.y,
                "小雨" to R.drawable.xy,
                "中雨" to R.drawable.zhy,
                "大雨" to R.drawable.dby,
                "暴雨" to R.drawable.dby,
                "阵雨" to R.drawable.zy,
                "雷阵雨" to R.drawable.lzy,
                "冻雨" to R.drawable.dy,
                "雨夹雪" to R.drawable.yjx,
                "小雪" to R.drawable.xx,
                "中雪" to R.drawable.zx,
                "大雪" to R.drawable.dx,
                "暴雪" to R.drawable.bx,
                "雾" to R.drawable.w,
                "霾" to R.drawable.scb,
                "沙尘暴" to R.drawable.scb,
                "扬沙" to R.drawable.scb,
                "浮尘" to R.drawable.scb
            )
            
            // 夜间图标映射
            val nightIconMap = mapOf(
                "晴" to R.drawable.q0,
                "多云" to R.drawable.dy0,
                "多云转晴" to R.drawable.dyq0,
                "晴转多云" to R.drawable.dyq0,
                "阴" to R.drawable.y,
                "小雨" to R.drawable.xy,
                "中雨" to R.drawable.zhy,
                "大雨" to R.drawable.dby,
                "暴雨" to R.drawable.dby,
                "阵雨" to R.drawable.zy0,
                "雷阵雨" to R.drawable.lzy0,
                "冻雨" to R.drawable.dy0,
                "雨夹雪" to R.drawable.yjx,
                "小雪" to R.drawable.xx,
                "中雪" to R.drawable.zx,
                "大雪" to R.drawable.dx0,
                "暴雪" to R.drawable.bx,
                "雾" to R.drawable.w,
                "霾" to R.drawable.scb,
                "沙尘暴" to R.drawable.scb,
                "扬沙" to R.drawable.scb,
                "浮尘" to R.drawable.scb
            )
            
            val iconMap = if (isDaytime) dayIconMap else nightIconMap
            
            // 精确匹配
            iconMap[weatherText]?.let { return it }
            
            // 模糊匹配
            for ((key, value) in iconMap) {
                if (weatherText.contains(key)) {
                    return value
                }
            }
            
            // 默认返回晴天图标
            return if (isDaytime) R.drawable.q else R.drawable.q0
        }
    }
}

