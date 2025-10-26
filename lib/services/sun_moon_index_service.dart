import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sun_moon_index_model.dart';

class SunMoonIndexService {
  static const String _baseUrl =
      'https://www.weatherol.cn/api/home/getSunMoonAndIndex';

  static Future<SunMoonIndexResponse?> getSunMoonAndIndex(String cityId) async {
    try {
      final url = Uri.parse('$_baseUrl?cityid=$cityId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SunMoonIndexResponse.fromJson(jsonData);
      } else {
        print('Failed to load sun/moon index data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching sun/moon index data: $e');
      return null;
    }
  }
}
