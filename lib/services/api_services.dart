import 'dart:convert';
import 'package:http/http.dart' as http;

class ExternalApis {
  // 1. ZenQuotes API (Motivation)
  static Future<String> getDailyQuote() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return '"${data[0]['q']}"\n- ${data[0]['a']}';
      }
    } catch (e) {
      return '"The secret of getting ahead is getting started."\n- Mark Twain'; // Fallback
    }
    return 'Keep pushing forward!';
  }

  // 2. World Time API (Bulletproof Deadlines)
  static Future<DateTime> getTrueNetworkTime() async {
    try {
      final response = await http.get(Uri.parse('http://worldtimeapi.org/api/timezone/Asia/Kuala_Lumpur'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DateTime.parse(data['datetime']);
      }
    } catch (e) {
      return DateTime.now(); // Fallback to device time if offline
    }
    return DateTime.now();
  }
}