import 'task_model.dart';

class AIResponse {
  final List<TaskModel> tasks;
  final String advice;

  AIResponse({required this.tasks, required this.advice});
}
