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
      2. NẾU THỜI TIẾT XẤU NHƯ BÃO, MƯA TO HOẶC GIÔNG MẠNH, hãy tránh xếp các việc ngoài trời. Nếu chỉ là "Mưa giông rải rác" hoặc "Mưa rào rải rác", hãy linh hoạt sắp xếp việc ngoài trời vào các khung giờ phù hợp (ví dụ tránh chiều muộn), hoặc gợi ý các hoạt động trong nhà. Nếu thời tiết nắng nóng (trên 35°C), khuyên người dùng hạn chế ra ngoài lúc trưa/chiều và nên tập thể dục trong nhà hoặc sáng sớm/chiều mát.
      3. Đối với cảnh báo thời tiết trong trường "advice":
         - CHỈ đưa ra cảnh báo thời tiết và nhắc nhở mang theo vật dụng nếu trong danh sách "tasks" đề xuất có công việc diễn ra NGOÀI TRỜI (outdoor).
         - Nếu công việc ở ngoài trời và dự báo có mưa/giông: Nhắc nhở người dùng mang theo ô (dù), áo mưa.
         - Nếu công việc ở ngoài trời và dự báo có nắng to/nắng nóng: Nhắc nhở người dùng mang theo kem chống nắng, mũ (nón), kính râm, hoặc nước uống để bảo vệ sức khỏe.
         - Nếu tất cả công việc đề xuất đều ở TRONG NHÀ (indoor) hoặc không bị ảnh hưởng bởi thời tiết, KHÔNG đưa ra cảnh báo thời tiết trong trường "advice" (để trống hoặc chỉ đưa ra cảnh báo quá tải nếu lịch quá dày).
      4. Nếu lịch hiện tại quá dày, hãy đưa ra lời khuyên tránh quá tải (burnout) trong trường "advice", và dãn việc ra.
      5. Tránh xếp lịch trùng với những việc đã có.

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
