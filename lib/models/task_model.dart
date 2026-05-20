class TaskModel {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  final String details;
  bool isCompleted;

  TaskModel({
    required this.id,
    required this.title,
    required this.date,
    this.time = '',
    this.details = '',
    this.isCompleted = false,
  });
}
