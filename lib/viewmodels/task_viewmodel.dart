import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/ai_response.dart';
import '../repositories/task_repository.dart';
import '../services/ai_service.dart';
import '../services/notification_service.dart';

// Single Responsibility Principle: Handles state and business logic for tasks
// Dependency Inversion Principle: Relies on abstractions (ITaskRepository, IAIService)
class TaskViewModel extends ChangeNotifier {
  final ITaskRepository _repository;
  final IAIService _aiService;

  DateTime _selectedDate = DateTime.now();
  List<TaskModel> _currentTasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _aiAdvice;

  TaskViewModel({
    required ITaskRepository repository,
    required IAIService aiService,
  })  : _repository = repository,
        _aiService = aiService {
    _loadTasksForSelectedDate();
  }

  DateTime get selectedDate => _selectedDate;
  List<TaskModel> get currentTasks => _currentTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get aiAdvice => _aiAdvice;

  void clearAiAdvice() {
    _aiAdvice = null;
    notifyListeners();
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    _loadTasksForSelectedDate();
  }

  Future<void> _loadTasksForSelectedDate() async {
    _currentTasks = await _repository.getTasksForDate(_selectedDate);
    notifyListeners();
  }

  List<TaskModel> getTasksForDay(DateTime day) {
    return _repository.getTasksForDateSync(day);
  }

  Future<void> addTask(String title, DateTime date, {String time = '', String details = ''}) async {
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      time: time,
      details: details,
    );
    await _repository.addTask(newTask);
    
    // Parse time if available, otherwise default to 8:00 AM
    int hour = 8;
    int minute = 0;
    if (time.isNotEmpty && time.contains(':')) {
      final parts = time.split(':');
      hour = int.tryParse(parts[0]) ?? 8;
      minute = int.tryParse(parts[1]) ?? 0;
    }

    // Schedule Notification
    final taskTime = DateTime(date.year, date.month, date.day, hour, minute);
    final scheduleTime = taskTime.subtract(const Duration(minutes: 15));
    NotificationService().scheduleNotification(
      id: newTask.id.hashCode,
      title: 'Nhắc nhở công việc',
      body: 'Còn 15 phút nữa: $title',
      scheduledDate: scheduleTime,
    );

    if (_isSameDay(date, _selectedDate)) {
      _loadTasksForSelectedDate();
    }
  }

  Future<void> toggleTaskCompletion(TaskModel task, bool isCompleted) async {
    task.isCompleted = isCompleted;
    await _repository.updateTask(task);
    _loadTasksForSelectedDate();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _loadTasksForSelectedDate();
  }

  Future<AIResponse?> generateTasksWithAI(String prompt) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allTasks = await _repository.getAllTasks();
      final aiResponse = await _aiService.generateTasksFromPrompt(prompt, allTasks);
      return aiResponse;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addAIGeneratedTasks(List<TaskModel> tasks, {String? advice}) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (advice != null && advice.isNotEmpty) {
        _aiAdvice = advice;
      }
      for (var task in tasks) {
        await _repository.addTask(task);
        
        int hour = 8;
        int minute = 0;
        if (task.time.isNotEmpty && task.time.contains(':')) {
          final parts = task.time.split(':');
          hour = int.tryParse(parts[0]) ?? 8;
          minute = int.tryParse(parts[1]) ?? 0;
        }

        final taskTime = DateTime(task.date.year, task.date.month, task.date.day, hour, minute);
        final scheduleTime = taskTime.subtract(const Duration(minutes: 15));
        NotificationService().scheduleNotification(
          id: task.id.hashCode,
          title: 'Lịch trình AI',
          body: 'Còn 15 phút nữa: ${task.title}',
          scheduledDate: scheduleTime,
        );
      }
      _loadTasksForSelectedDate();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<Map<String, dynamic>> getWeeklyStats() async {
    final allTasks = await _repository.getAllTasks();
    final now = DateTime.now();
    int totalCompleted = 0;
    int totalTasks = 0;
    
    List<double> completedPerDay = List.filled(7, 0);
    List<double> totalPerDay = List.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      // Bắt đầu từ hôm nay đến 6 ngày tiếp theo trong tương lai
      final day = now.add(Duration(days: i));
      for (var task in allTasks) {
        if (_isSameDay(task.date, day)) {
          totalTasks++;
          totalPerDay[i]++;
          if (task.isCompleted) {
            totalCompleted++;
            completedPerDay[i]++;
          }
        }
      }
    }

    return {
      'total': totalTasks,
      'completed': totalCompleted,
      'completedPerDay': completedPerDay,
      'totalPerDay': totalPerDay,
    };
  }
}
