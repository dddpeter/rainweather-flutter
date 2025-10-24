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
                
                // 读取顶部区域数据
                val location = prefs.getString("flutter.location", null) ?: "未知位置"
                val gregorianDate = prefs.getString("flutter.gregorian_date", null) ?: "--月--日 星期--"
                val currentTemp = prefs.getString("flutter.current_temp", null) ?: "--°"
                val currentWeather = prefs.getString("flutter.current_weather", null) ?: "未知"
                val currentWeatherIcon = prefs.getString("flutter.current_weather_icon", null) ?: ""
                val todayHigh = prefs.getString("flutter.today_high", null) ?: "最高 --°"
                val todayLow = prefs.getString("flutter.today_low", null) ?: "最低 --°"

                // 读取农历和空气质量数据
                val lunarDate = prefs.getString("flutter.lunar_date", null) ?: "农历 --"
                val airQuality = prefs.getString("flutter.air_quality", null) ?: "空气质量 --"

                // 读取生活提示数据
                val lifeTips = prefs.getString("flutter.life_tips", null) ?: "生活提示：建议穿薄外套，无需带伞"

                // 更新顶部区域
                views.setTextViewText(R.id.text_location_name, location)
                views.setTextViewText(R.id.text_gregorian_date, gregorianDate)
                views.setTextViewText(R.id.text_lunar_date, lunarDate)
                views.setTextViewText(R.id.text_current_temp, currentTemp)
                views.setTextViewText(R.id.text_current_weather, currentWeather)
                views.setTextViewText(R.id.text_today_high, todayHigh)
                views.setTextViewText(R.id.text_today_low, todayLow)
                
                // 更新空气质量
                views.setTextViewText(R.id.text_air_quality, airQuality)
                
                // 更新生活提示
                views.setTextViewText(R.id.text_life_tips, lifeTips)
                
                // 更新当前天气图标
                val isDaytime = isDaytime(currentWeatherIcon)
                val weatherIconRes = getWeatherIcon(currentWeather, isDaytime)
                views.setImageViewResource(R.id.image_current_weather_icon, weatherIconRes)

                // 更新24小时预报
                val hourlyForecastJson = prefs.getString("flutter.hourly_forecast", null) ?: "[]"
                updateHourlyForecast(views, hourlyForecastJson, isDaytime)

                // 更新5日预报
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

        private fun updateHourlyForecast(views: RemoteViews, jsonStr: String, isDaytime: Boolean) {
            try {
                val jsonArray = JSONArray(jsonStr)
                
                data class HourlyIds(
                    val time: Int,
                    val weather: Int,
                    val temp: Int
                )
                
                       val hourlyIds = listOf(
                           HourlyIds(R.id.hourly_time_1, R.id.hourly_weather_1, R.id.hourly_temp_1),
                           HourlyIds(R.id.hourly_time_2, R.id.hourly_weather_2, R.id.hourly_temp_2),
                           HourlyIds(R.id.hourly_time_3, R.id.hourly_weather_3, R.id.hourly_temp_3),
                           HourlyIds(R.id.hourly_time_4, R.id.hourly_weather_4, R.id.hourly_temp_4),
                           HourlyIds(R.id.hourly_time_5, R.id.hourly_weather_5, R.id.hourly_temp_5),
                           HourlyIds(R.id.hourly_time_6, R.id.hourly_weather_6, R.id.hourly_temp_6),
                           HourlyIds(R.id.hourly_time_7, R.id.hourly_weather_7, R.id.hourly_temp_7),
                           HourlyIds(R.id.hourly_time_8, R.id.hourly_weather_8, R.id.hourly_temp_8)
                       )
                
                for (i in 0 until minOf(jsonArray.length(), 8)) {
                    val item = jsonArray.getJSONObject(i)
                    val time = item.optString("time", "")
                    val weatherIconText = item.optString("weatherIcon", "")
                    val weatherText = item.optString("weatherText", "")
                    
                    // 根据天气图标名称判断白天/夜间
                    val isHourlyDaytime = isDaytime(weatherIconText)
                    val weatherIconRes = getWeatherIcon(weatherText, isHourlyDaytime)
                    val temp = item.optString("temperature", "--").replace("°", "°")
                    
                    views.setTextViewText(hourlyIds[i].time, time)
                    views.setImageViewResource(hourlyIds[i].weather, weatherIconRes)
                    views.setTextViewText(hourlyIds[i].temp, temp)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        private fun updateForecast(views: RemoteViews, jsonStr: String, isDaytime: Boolean) {
            try {
                val jsonArray = JSONArray(jsonStr)
                
                data class ForecastIds(
                    val weekday: Int,
                    val weather: Int,
                    val tempHigh: Int,
                    val tempLow: Int,
                    val highProgress: Int,
                    val lowProgress: Int
                )
                
                val dayIds = listOf(
                    ForecastIds(R.id.forecast_day1_weekday, R.id.forecast_day1_weather, R.id.forecast_day1_temp_high, R.id.forecast_day1_temp_low, R.id.forecast_day1_high_progress, R.id.forecast_day1_low_progress),
                    ForecastIds(R.id.forecast_day2_weekday, R.id.forecast_day2_weather, R.id.forecast_day2_temp_high, R.id.forecast_day2_temp_low, R.id.forecast_day2_high_progress, R.id.forecast_day2_low_progress),
                    ForecastIds(R.id.forecast_day3_weekday, R.id.forecast_day3_weather, R.id.forecast_day3_temp_high, R.id.forecast_day3_temp_low, R.id.forecast_day3_high_progress, R.id.forecast_day3_low_progress),
                    ForecastIds(R.id.forecast_day4_weekday, R.id.forecast_day4_weather, R.id.forecast_day4_temp_high, R.id.forecast_day4_temp_low, R.id.forecast_day4_high_progress, R.id.forecast_day4_low_progress),
                    ForecastIds(R.id.forecast_day5_weekday, R.id.forecast_day5_weather, R.id.forecast_day5_temp_high, R.id.forecast_day5_temp_low, R.id.forecast_day5_high_progress, R.id.forecast_day5_low_progress)
                )
                
                for (i in 0 until minOf(jsonArray.length(), 5)) {
                    val item = jsonArray.getJSONObject(i)
                    val weekday = item.optString("weekday", "")
                    val weatherIconText = item.optString("weatherIcon", "")
                    val weatherIconRes = getWeatherIcon(weatherIconText, isDaytime)
                    val high = item.optString("tempHigh", "--").replace("°", "°")
                    val low = item.optString("tempLow", "--").replace("°", "°")
                    val highProgress = item.optInt("progressPercent", 50)
                    val lowProgress = item.optInt("lowProgressPercent", 30)
                    
                    // 调试输出
                    android.util.Log.d("WeatherWidget", "第${i+1}天: 高温进度=$highProgress%, 低温进度=$lowProgress%")
                    android.util.Log.d("WeatherWidget", "第${i+1}天: 高温ID=${dayIds[i].highProgress}, 低温ID=${dayIds[i].lowProgress}")
                    
                    // 设置星期、天气图标和温度
                    views.setTextViewText(dayIds[i].weekday, weekday)
                    views.setImageViewResource(dayIds[i].weather, weatherIconRes)
                    views.setTextViewText(dayIds[i].tempHigh, high)
                    views.setTextViewText(dayIds[i].tempLow, low)
                    
                    // 设置双进度条
                    views.setProgressBar(dayIds[i].highProgress, 100, highProgress, false)
                    views.setProgressBar(dayIds[i].lowProgress, 100, lowProgress, false)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        /**
         * 判断是否为白天
         * 根据天气图标名称判断，以 'd' 开头为白天，以 'n' 开头为夜间
         */
        private fun isDaytime(weatherIcon: String): Boolean {
            return weatherIcon.startsWith("d")
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

