import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../viewmodels/task_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../services/weather_service.dart';
import 'widgets/floating_app_icon.dart';
import 'dashboard_screen.dart';
import '../models/task_model.dart';
import '../models/ai_response.dart';

// Single Responsibility Principle: Handles only the Presentation layer
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _showGreetingWithWeather();
  }

  Future<void> _showGreetingWithWeather() async {
    // Import package 'package:task/services/weather_service.dart' if needed
    final weatherMessage = await WeatherService().getTodayWeatherSummary();
    
    if (mounted) {
      FloatingAppIcon.show(
        context,
        imageAssetPath: 'assets/images/appIconLight.jpg',
        message: weatherMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe trạng thái từ ViewModel
    final viewModel = context.watch<TaskViewModel>();
    final selectedTasks = viewModel.currentTasks;

    // Lắng nghe và hiển thị lỗi nếu có
    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FloatingAppIcon.show(
          context,
          imageAssetPath: 'assets/images/appIconLight.jpg',
          message: viewModel.errorMessage!,
        );
        viewModel.clearErrorMessage();
      });
    }
    
    if (viewModel.aiAdvice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FloatingAppIcon.show(
          context,
          imageAssetPath: 'assets/images/appIconLight.jpg',
          message: viewModel.aiAdvice!,
        );
        viewModel.clearAiAdvice();
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF1A1A2E) 
          : const Color(0xFFF0F8FF), // Alice Blue cho cảm giác bầu trời
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logoHoziontalLight.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.child_care, color: Colors.orange, size: 36),
            ),
            const SizedBox(width: 8),
            
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          viewModel.isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 4, color: Colors.orange)),
                  ),
                )
              : Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
                        tooltip: 'Thành Tích',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const DashboardScreen()),
                          );
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                        tooltip: 'Trợ lý thần kỳ',
                        onPressed: () => _showAIInputDialog(context, viewModel),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                        tooltip: 'Cài Đặt',
                        onPressed: () => _showSettingsDialog(context),
                      ),
                    ),
                  ],
                ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(viewModel.selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(viewModel.selectedDate, selectedDay)) {
                  viewModel.setSelectedDate(selectedDay);
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                formatButtonDecoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                weekendTextStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.redAccent),
                selectedDecoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
                todayDecoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                ),
              ),
              eventLoader: viewModel.getTasksForDay,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orangeAccent, width: 2),
                        ),
                        child: Text(
                          '📅 Ngày ${DateFormat('dd/MM').format(viewModel.selectedDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${selectedTasks.where((t) => t.isCompleted).length}/${selectedTasks.length} Xong',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showAddTaskDialog(context, viewModel),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.pinkAccent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: selectedTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/images/appIconLight.jpg', height: 120, errorBuilder: (c,e,s) => const Icon(Icons.sentiment_very_satisfied, size: 100, color: Colors.orangeAccent)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Hoan hô! Bé không có bài tập nào hôm nay.',
                                  style: TextStyle(color: Colors.blueGrey, fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: selectedTasks.length,
                            itemBuilder: (context, index) {
                              final task = selectedTasks[index];
                              // Mảng màu sắc rực rỡ cho trẻ em
                              final colors = [
                                const Color(0xFFFFCDD2), // Đỏ nhạt
                                const Color(0xFFC8E6C9), // Xanh lá nhạt
                                const Color(0xFFFFF9C4), // Vàng nhạt
                                const Color(0xFFE1BEE7), // Tím nhạt
                                const Color(0xFFBBDEFB), // Xanh dương nhạt
                              ];
                              final cardColor = colors[index % colors.length];

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: cardColor.withOpacity(0.6),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: task.isCompleted ? Colors.green : Colors.transparent,
                                    width: 3,
                                  )
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  leading: Transform.scale(
                                    scale: 1.5,
                                    child: Checkbox(
                                      value: task.isCompleted,
                                      activeColor: Colors.green,
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      onChanged: (bool? value) {
                                        viewModel.toggleTaskCompletion(task, value ?? false);
                                      },
                                    ),
                                  ),
                                  title: Text(
                                    task.time.isNotEmpty ? '${task.time} - ${task.title}' : task.title,
                                    style: TextStyle(
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted ? Colors.grey[700] : Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: task.details.isNotEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            task.details,
                                            style: TextStyle(
                                              decoration: task.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: task.isCompleted ? Colors.grey[500] : Colors.black54,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 30),
                                    onPressed: () {
                                      viewModel.deleteTask(task.id);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Transform.scale(
        scale: 1.1,
        child: FloatingActionButton.extended(
          heroTag: 'aiGenieFAB',
          onPressed: () => _showAIInputDialog(context, viewModel),
          backgroundColor: Colors.amberAccent,
          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          label: const Text('AI Thần Kỳ', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final settings = context.watch<SettingsViewModel>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cài Đặt', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Chế độ tối (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('Giao diện dịu mắt hơn', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                secondary: Icon(Icons.dark_mode, color: isDark ? Colors.amber : Colors.blueGrey),
                value: settings.isDarkMode,
                activeColor: Colors.amber,
                onChanged: (value) => settings.toggleTheme(value),
              ),
              SwitchListTile(
                title: Text('Âm thanh & Hiệu ứng', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('Phát tiếng khen thưởng khi hoàn thành', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                secondary: Icon(settings.isSoundEnabled ? Icons.volume_up : Icons.volume_off, color: isDark ? Colors.amber : Colors.blueGrey),
                value: settings.isSoundEnabled,
                activeColor: Colors.amber,
                onChanged: (value) => settings.toggleSound(value),
              ),
              SwitchListTile(
                title: Text('Nhắc nhở thông báo', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('Gửi thông báo nhắc việc mỗi ngày', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                secondary: Icon(settings.isNotificationsEnabled ? Icons.notifications_active : Icons.notifications_off, color: isDark ? Colors.amber : Colors.blueGrey),
                value: settings.isNotificationsEnabled,
                activeColor: Colors.amber,
                onChanged: (value) => settings.toggleNotifications(value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng', style: TextStyle(fontSi  void _showAddTaskDialog(BuildContext context, TaskViewModel viewModel) {
    final TextEditingController timeController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header với gradient đẹp mắt
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pinkAccent, Colors.orangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      width: double.infinity,
                      child: const Column(
                        children: [
                          Icon(Icons.add_task_rounded, color: Colors.white, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Thêm công việc mới 📝',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Phần content nhập liệu
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: timeController,
                            readOnly: true,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Thời gian (*)',
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                              hintText: 'Chọn thời gian',
                              suffixIcon: const Icon(Icons.access_time_rounded, color: Colors.orangeAccent),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : Colors.orange.shade50.withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
                              ),
                            ),
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  timeController.text = picked.format(context);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: titleController,
                            autofocus: true,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Tên công việc (*)',
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                              hintText: 'VD: Học bài, giúp mẹ dọn nhà...',
                              filled: true,
                              fillColor: isDark ? Colors.white10 : Colors.pink.shade50.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.5)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.pinkAccent.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.pinkAccent, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: detailsController,
                            maxLines: 2,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Chi tiết (Tùy chọn)',
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                              hintText: 'Mô tả thêm cho công việc...',
                              filled: true,
                              fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Hàng nút hành động
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'Hủy bỏ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.pinkAccent, Colors.orangeAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pinkAccent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (timeController.text.isEmpty || titleController.text.isEmpty) {
                                      FloatingAppIcon.show(context, imageAssetPath: 'assets/images/appIconLight.jpg', message: 'Bé nhớ nhập đủ thời gian và tên công việc nhé!');
                                      return;
                                    }
                                    viewModel.addTask(
                                      titleController.text, 
                                      viewModel.selectedDate,
                                      time: timeController.text,
                                      details: detailsController.text,
                                    );
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Thêm ngay',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAIInputDialog(BuildContext context, TaskViewModel viewModel) {
    final TextEditingController aiController = TextEditingController();
    bool isListening = false;
    final stt.SpeechToText speech = stt.SpeechToText();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Trợ lý AI với gradient vàng/amber
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber, Colors.orangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      width: double.infinity,
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trợ lý AI Thần Kỳ 🔮',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Nói hoặc viết lịch trình để AI sắp xếp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Nút Mic
                          GestureDetector(
                            onTap: () async {
                              if (!isListening) {
                                bool available = await speech.initialize(
                                  onStatus: (val) {
                                    if (val == 'done' || val == 'notListening') {
                                      setState(() => isListening = false);
                                    }
                                  },
                                  onError: (val) {
                                    print('onError: $val');
                                    setState(() => isListening = false);
                                  },
                                );
                                if (available) {
                                  setState(() => isListening = true);
                                  speech.listen(
                                    onResult: (val) {
                                      setState(() {
                                        aiController.text = val.recognizedWords;
                                        aiController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: aiController.text.length),
                                        );
                                      });
                                    },
                                    localeId: 'vi_VN',
                                  );
                                }
                              } else {
                                setState(() => isListening = false);
                                speech.stop();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isListening ? Colors.redAccent : Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content nhập liệu AI
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: aiController,
                            maxLines: 3,
                            autofocus: true,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập lịch trình hoặc bấm Mic để nói...',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : Colors.amber.shade50.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.amber.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.amber.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Colors.amber, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Hàng nút hành động
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  speech.stop();
                                  Navigator.pop(dialogContext);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'Hủy bỏ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orangeAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (aiController.text.isNotEmpty) {
                                      final text = aiController.text;
                                      speech.stop();
                                      Navigator.pop(dialogContext);
                                      
                                      final aiResponse = await viewModel.generateTasksWithAI(text);
                                      if (aiResponse != null && context.mounted) {
                                        if (aiResponse.tasks.isEmpty) {
                                          FloatingAppIcon.show(
                                            context,
                                            imageAssetPath: 'assets/images/appIconLight.jpg',
                                            message: aiResponse.advice.isNotEmpty 
                                                ? aiResponse.advice 
                                                : 'AI không tìm thấy công việc nào phù hợp từ mô tả của bạn.',
                                          );
                                        } else {
                                          _showAIConfirmationDialog(context, viewModel, aiResponse);
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                                  label: const Text(
                                    'Tạo Lịch Trình',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAIConfirmationDialog(BuildContext context, TaskViewModel viewModel, AIResponse aiResponse) {
    // Keep track of which tasks are selected to add
    final List<TaskModel> selectedTasks = List.from(aiResponse.tasks);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final adviceBgColor = isDark ? Colors.amber.shade900.withOpacity(0.2) : Colors.amber.shade50;
            final adviceBorderColor = isDark ? Colors.amber.shade800 : Colors.amberAccent;
            final adviceTextColor = isDark ? Colors.amber.shade100 : Colors.black87;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header đẹp
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.lightBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      width: double.infinity,
                      child: const Column(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Lịch trình đề xuất 🌟',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // AI Advice Box
                          if (aiResponse.advice.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: adviceBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: adviceBorderColor, width: 1.5),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      aiResponse.advice,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: adviceTextColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          Text(
                            'Các công việc do AI gợi ý:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Task List
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.35,
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: aiResponse.tasks.length,
                                itemBuilder: (context, index) {
                                  final task = aiResponse.tasks[index];
                                  final isSelected = selectedTasks.contains(task);
                                  final dateStr = DateFormat('dd/MM').format(task.date);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark ? Colors.blueAccent.withOpacity(0.15) : Colors.blue.shade50)
                                          : (isDark ? Colors.white10 : Colors.grey.shade100),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? Colors.blueAccent : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      activeColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${task.time.isNotEmpty ? task.time : "Cả ngày"} - Ngày $dateStr${task.details.isNotEmpty ? "\n${task.details}" : ""}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white70 : Colors.black54,
                                        ),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            selectedTasks.add(task);
                                          } else {
                                            selectedTasks.remove(task);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Hàng nút hành động
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  FloatingAppIcon.show(
                                    context,
                                    imageAssetPath: 'assets/images/appIconLight.jpg',
                                    message: 'Đã hủy bỏ đề xuất lịch trình. ❌',
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text(
                                  'Hủy bỏ',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: selectedTasks.isEmpty
                                      ? null
                                      : () {
                                          viewModel.addAIGeneratedTasks(selectedTasks, advice: aiResponse.advice);
                                          Navigator.pop(context);
                                          FloatingAppIcon.show(
                                            context,
                                            imageAssetPath: 'assets/images/appIconLight.jpg',
                                            message: 'Tuyệt vời! Đã thêm các công việc vào lịch trình. 🎉',
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Đồng ý thêm',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}�ồng ý và Thêm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
