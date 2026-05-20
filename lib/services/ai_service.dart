import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/ai_response.dart';
import 'weather_service.dart';

// Open/Closed Principle & Dependency Inversion Principle
abstract class IAIService {
  Future<AIResponse> generateTasksFromPrompt(String prompt, List<TaskModel> currentTasks);
}

// Liskov Substitution Principle: Mock implementation
class MockAIService implements IAIService {
  @override
  Future<AIResponse> generateTasksFromPrompt(String prompt, List<TaskModel> currentTasks) async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network

    final lowerPrompt = prompt.toLowerCase();
    int offset = 0;
    if (lowerPrompt.contains('mai') || lowerPrompt.contains('ngày mai')) {
      offset = 1;
    }

    final taskDate = DateTime.now().add(Duration(days: offset));
    List<TaskModel> generatedTasks = [];

    generatedTasks.add(TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'AI Task: $prompt',
      date: taskDate,
      time: '09:00',
      details: 'Chi tiết mẫu từ AI',
    ));

    return AIResponse(tasks: generatedTasks, advice: "Đây là lời khuyên mẫu từ Mock AI");
  }
}

// Liskov Substitution Principle: Real implementation
class GeminiAIService implements IAIService {
  final String apiKey;

  GeminiAIService({required this.apiKey});

  @override
  Future<AIResponse> generateTasksFromPrompt(String prompt, List<TaskModel> currentTasks) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Vui lòng cung cấp API Key hợp lệ');
    }

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    
    // Lấy thông tin thời tiết
    final weatherSummary = await WeatherService().getWeeklyWeatherSummary();

    // Thu thập lịch hiện tại để AI tránh trùng lịch
    final currentTasksJson = currentTasks.map((t) => {
      "title": t.title, 
      "date": t.date.toIso8601String()
    }).toList();

    final content = [Content.text('''
      Bạn là trợ lý ảo lên lịch trình thông minh.
      Mục tiêu hoặc lệnh của người dùng: "$prompt"
      Hôm nay là: ${DateTime.now().toIso8601String()}
      Lịch hiện tại của người dùng: ${jsonEncode(currentTasksJson)}
      
      Thông tin thời tiết:
      $weatherSummary

      Yêu cầu:
      1. Nếu là mục tiêu lớn, hãy chia nhỏ thành các công việc theo từng ngày.
      2. NẾU THỜI TIẾT XẤU (Mưa, bão...), KHÔNG xếp các việc ngoài trời, GỢI Ý đổi sang các việc trong nhà. NẾU THỜI TIẾT ĐẸP, có thể gợi ý hoạt động ngoài trời.
      3. Nếu lịch hiện tại quá dày, hãy đưa ra lời khuyên tránh quá tải (burnout) trong trường "advice", và dãn việc ra.
      4. Tránh xếp lịch trùng với những việc đã có.

      Trả về ĐÚNG định dạng JSON sau (không chứa text dư thừa):
      {
        "advice": "Lời khuyên, nhắc nhở về thời tiết hoặc cảnh báo quá tải...",
        "tasks": [
          {
            "title": "Tên công việc",
            "offset": Số ngày tính từ hôm nay (int. 0 = hôm nay, 1 = ngày mai),
            "time": "Giờ cụ thể (VD: 08:00, 15:30. Chọn giờ hợp lý cho từng việc)",
            "details": "Chi tiết công việc hoặc ghi chú (nếu có)"
          }
        ]
      }
    ''')];

    final response = await model.generateContent(content);
    String resText = response.text ?? '{}';
    resText = resText.replaceAll('```json', '').replaceAll('```', '').trim();
    
    try {
      final Map<String, dynamic> data = jsonDecode(resText);
      final String advice = data['advice'] ?? '';
      final List<dynamic> tasksData = data['tasks'] ?? [];
      
      List<TaskModel> generatedTasks = [];
      for (var item in tasksData) {
        final int offset = item['offset'] ?? 0;
        final String title = item['title'] ?? 'Task';
        final String time = item['time'] ?? '08:00';
        final String details = item['details'] ?? '';
        final taskDate = DateTime.now().add(Duration(days: offset));
        
        generatedTasks.add(TaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString() + title,
          title: title,
          date: taskDate,
          time: time,
          details: details,
        ));
      }
      return AIResponse(tasks: generatedTasks, advice: advice);
    } catch (e) {
      throw Exception('Lỗi xử lý phản hồi từ AI: $e');
    }
  }
}
