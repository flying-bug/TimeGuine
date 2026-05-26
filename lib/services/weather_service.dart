import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Lấy toạ độ mặc định (Ví dụ: Hà Nội) nếu không xin được quyền
  static double latitude = 21.0285;
  static double longitude = 105.8542;

  Future<void> _updateLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      print("Không lấy được GPS: $e");
    }
  }

  /// Lấy thời tiết hôm nay để hiển thị ở bong bóng chat
  Future<String> getTodayWeatherSummary() async {
    await _updateLocation();
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&timezone=Asia%2FBangkok');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        final temp = current['temperature_2m'];
        final code = current['weather_code'];
        final condition = _getWeatherCondition(code);

        return "Hôm nay: $condition ($temp°C). Hãy chú ý sức khoẻ nhé!";
      }
    } catch (e) {
      print("Lỗi thời tiết: $e");
    }
    return "Xin chào! Cùng lên lịch hôm nay nhé.";
  }

  /// Lấy dự báo 7 ngày để gửi cho AI làm dữ liệu gợi ý
  Future<String> getWeeklyWeatherSummary() async {
    await _updateLocation();
    try {
      final url = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=Asia%2FBangkok');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final daily = data['daily'];
        final times = daily['time'] as List;
        final maxTemps = daily['temperature_2m_max'] as List;
        final minTemps = daily['temperature_2m_min'] as List;
        final codes = daily['weather_code'] as List;

        String summary = "Dự báo thời tiết 7 ngày tới:\n";
        for (int i = 0; i < times.length; i++) {
          final condition = _getWeatherCondition(codes[i]);
          summary += "- Ngày ${times[i]}: $condition, Nhiệt độ: ${minTemps[i]}°C - ${maxTemps[i]}°C\n";
        }
        return summary;
      }
    } catch (e) {
      print("Lỗi lấy thời tiết: $e");
    }
    return "Không có dữ liệu thời tiết.";
  }

  String _getWeatherCondition(int code) {
    if (code == 0) return 'Trời quang đãng / Nắng đẹp';
    if (code == 1 || code == 2 || code == 3) return 'Nhiều mây / Có mây';
    if (code == 45 || code == 48) return 'Sương mù';
    if (code >= 51 && code <= 67) return 'Có mưa nhẹ / Mưa rào';
    if (code >= 71 && code <= 77) return 'Tuyết rơi';
    if (code == 80 || code == 81) return 'Mưa rào rải rác';
    if (code == 82) return 'Mưa to';
    if (code == 95) return 'Mưa giông rải rác';
    if (code >= 96 && code <= 99) return 'Mưa giông mạnh / Bão';
    return 'Thời tiết thất thường';
  }
}
