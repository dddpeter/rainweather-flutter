import 'package:flutter_test/flutter_test.dart';

void main() {
  group('温度显示逻辑测试', () {
    /// 解析温度字符串为数值
    double parseTemperature(String tempStr) {
      try {
        String cleanStr = tempStr
            .replaceAll('高温', '')
            .replaceAll('低温', '')
            .replaceAll('℃', '')
            .replaceAll('°', '')
            .replaceAll(' ', '')
            .trim();
        if (cleanStr.isEmpty) return 0;
        return double.parse(cleanStr);
      } catch (e) {
        return 0;
      }
    }

    group('国内城市数据测试', () {
      // 国内城市：temperature_am = 高温，temperature_pm = 低温
      // 例如：temperature_am = "25℃", temperature_pm = "15℃"

      test('国内城市 - am=25, pm=15', () {
        const tempAm = '25';
        const tempPm = '15';

        final tempAmVal = parseTemperature(tempAm);
        final tempPmVal = parseTemperature(tempPm);
        final amIsLower = tempAmVal <= tempPmVal;

        print('国内城市测试: tempAm=$tempAmVal, tempPm=$tempPmVal, amIsLower=$amIsLower');

        // 国内城市：am > pm，所以 amIsLower = false
        expect(amIsLower, false, reason: '国内城市am是高温，应该大于pm');

        // 上午应该显示低温数据(pm)
        // 下午应该显示高温数据(am)
        final morningWeather = amIsLower ? 'weather_am' : 'weather_pm';
        final morningTemp = amIsLower ? tempAm : tempPm;
        final afternoonWeather = amIsLower ? 'weather_pm' : 'weather_am';
        final afternoonTemp = amIsLower ? tempPm : tempAm;

        expect(morningWeather, 'weather_pm', reason: '上午应该显示pm数据(低温)');
        expect(morningTemp, '15', reason: '上午应该显示低温15');
        expect(afternoonWeather, 'weather_am', reason: '下午应该显示am数据(高温)');
        expect(afternoonTemp, '25', reason: '下午应该显示高温25');
      });

      test('国内城市 - am=高温30, pm=低温20', () {
        const tempAm = '高温30';
        const tempPm = '低温20';

        final tempAmVal = parseTemperature(tempAm);
        final tempPmVal = parseTemperature(tempPm);
        final amIsLower = tempAmVal <= tempPmVal;

        print('国内城市测试(带中文): tempAm=$tempAmVal, tempPm=$tempPmVal, amIsLower=$amIsLower');

        expect(amIsLower, false);
      });
    });

    group('国际城市数据测试', () {
      // 国际城市：temperature_am = 低温，temperature_pm = 高温
      // 例如：temperature_am = "15℃", temperature_pm = "25℃"

      test('国际城市 - am=15, pm=25', () {
        const tempAm = '15';
        const tempPm = '25';

        final tempAmVal = parseTemperature(tempAm);
        final tempPmVal = parseTemperature(tempPm);
        final amIsLower = tempAmVal <= tempPmVal;

        print('国际城市测试: tempAm=$tempAmVal, tempPm=$tempPmVal, amIsLower=$amIsLower');

        // 国际城市：am < pm，所以 amIsLower = true
        expect(amIsLower, true, reason: '国际城市am是低温，应该小于pm');

        // 上午应该显示低温数据(am)
        // 下午应该显示高温数据(pm)
        final morningWeather = amIsLower ? 'weather_am' : 'weather_pm';
        final morningTemp = amIsLower ? tempAm : tempPm;
        final afternoonWeather = amIsLower ? 'weather_pm' : 'weather_am';
        final afternoonTemp = amIsLower ? tempPm : tempAm;

        expect(morningWeather, 'weather_am', reason: '上午应该显示am数据(低温)');
        expect(morningTemp, '15', reason: '上午应该显示低温15');
        expect(afternoonWeather, 'weather_pm', reason: '下午应该显示pm数据(高温)');
        expect(afternoonTemp, '25', reason: '下午应该显示高温25');
      });

      test('国际城市 - am=10°, pm=28°', () {
        const tempAm = '10°';
        const tempPm = '28°';

        final tempAmVal = parseTemperature(tempAm);
        final tempPmVal = parseTemperature(tempPm);
        final amIsLower = tempAmVal <= tempPmVal;

        print('国际城市测试(带°): tempAm=$tempAmVal, tempPm=$tempPmVal, amIsLower=$amIsLower');

        expect(amIsLower, true);
      });
    });

    group('边界情况测试', () {
      test('温度相等 - am=20, pm=20', () {
        const tempAm = '20';
        const tempPm = '20';

        final tempAmVal = parseTemperature(tempAm);
        final tempPmVal = parseTemperature(tempPm);
        final amIsLower = tempAmVal <= tempPmVal;

        print('温度相等测试: tempAm=$tempAmVal, tempPm=$tempPmVal, amIsLower=$amIsLower');

        // 相等时，amIsLower = true，上午显示am数据
        expect(amIsLower, true);
      });

      test('空字符串', () {
        final tempVal = parseTemperature('');
        expect(tempVal, 0);
      });

      test('包含℃符号', () {
        final tempVal = parseTemperature('25℃');
        expect(tempVal, 25.0);
      });

      test('包含空格', () {
        final tempVal = parseTemperature(' 25 ');
        expect(tempVal, 25.0);
      });
    });

    group('完整模拟 - 预报卡片显示逻辑', () {
      test('国内城市完整流程', () {
        // 模拟国内城市数据
        const day = {
          'weather_am': '晴',
          'weather_pm': '多云',
          'temperature_am': '30',
          'temperature_pm': '18',
          'weather_am_pic': 'd00',
          'weather_pm_pic': 'n00',
        };

        final tempAm = parseTemperature(day['temperature_am']!);
        final tempPm = parseTemperature(day['temperature_pm']!);
        final amIsLower = tempAm <= tempPm;

        print('\n=== 国内城市完整流程 ===');
        print('tempAm=$tempAm, tempPm=$tempPm, amIsLower=$amIsLower');

        // 上午数据
        final morningWeather = amIsLower ? day['weather_am'] : day['weather_pm'];
        final morningTemp = amIsLower ? day['temperature_am'] : day['temperature_pm'];

        // 下午数据
        final afternoonWeather = amIsLower ? day['weather_pm'] : day['weather_am'];
        final afternoonTemp = amIsLower ? day['temperature_pm'] : day['temperature_am'];

        print('上午: $morningWeather, $morningTemp°C');
        print('下午: $afternoonWeather, $afternoonTemp°C');

        // 验证：上午显示低温，下午显示高温
        expect(morningTemp, '18', reason: '上午应显示低温18');
        expect(afternoonTemp, '30', reason: '下午应显示高温30');
        expect(morningWeather, '多云', reason: '上午应显示pm天气');
        expect(afternoonWeather, '晴', reason: '下午应显示am天气');
      });

      test('国际城市完整流程', () {
        // 模拟国际城市数据
        const day = {
          'weather_am': 'Cloudy',
          'weather_pm': 'Sunny',
          'temperature_am': '12',
          'temperature_pm': '26',
          'weather_am_pic': 'd00',
          'weather_pm_pic': 'n00',
        };

        final tempAm = parseTemperature(day['temperature_am']!);
        final tempPm = parseTemperature(day['temperature_pm']!);
        final amIsLower = tempAm <= tempPm;

        print('\n=== 国际城市完整流程 ===');
        print('tempAm=$tempAm, tempPm=$tempPm, amIsLower=$amIsLower');

        // 上午数据
        final morningWeather = amIsLower ? day['weather_am'] : day['weather_pm'];
        final morningTemp = amIsLower ? day['temperature_am'] : day['temperature_pm'];

        // 下午数据
        final afternoonWeather = amIsLower ? day['weather_pm'] : day['weather_am'];
        final afternoonTemp = amIsLower ? day['temperature_pm'] : day['temperature_am'];

        print('上午: $morningWeather, $morningTemp°C');
        print('下午: $afternoonWeather, $afternoonTemp°C');

        // 验证：上午显示低温，下午显示高温
        expect(morningTemp, '12', reason: '上午应显示低温12');
        expect(afternoonTemp, '26', reason: '下午应显示高温26');
        expect(morningWeather, 'Cloudy', reason: '上午应显示am天气');
        expect(afternoonWeather, 'Sunny', reason: '下午应显示pm天气');
      });
    });
  });
}
