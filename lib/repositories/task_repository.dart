import '../models/task_model.dart';

// Interface Segregation Principle
abstract class ITaskRepository {
  Future<List<TaskModel>> getTasksForDate(DateTime date);
  Future<List<TaskModel>> getAllTasks();
  List<TaskModel> getTasksForDateSync(DateTime date);
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
}

// Single Responsibility Principle
class InMemoryTaskRepository implements ITaskRepository {
  final Map<DateTime, List<TaskModel>> _tasks = {};

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    return _tasks.values.expand((element) => element).toList();
  }

  @override
  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    return _tasks[_normalizeDate(date)] ?? [];
  }

  @override
  List<TaskModel> getTasksForDateSync(DateTime date) {
    return _tasks[_normalizeDate(date)] ?? [];
  }

  @override
  Future<void> addTask(TaskModel task) async {
    final day = _normalizeDate(task.date);
    if (_tasks[day] == null) {
      _tasks[day] = [];
    }
    _tasks[day]!.add(task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final day = _normalizeDate(task.date);
    final tasks = _tasks[day] ?? [];
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    for (var tasksList in _tasks.values) {
      tasksList.removeWhere((task) => task.id == id);
    }
  }
}
