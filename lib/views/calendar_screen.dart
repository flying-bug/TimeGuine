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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orangeAccent, width: 2),
                        ),
                        child: Text(
                          '📅 Ngày ${DateFormat('dd/MM').format(viewModel.selectedDate)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${selectedTasks.where((t) => t.isCompleted).length}/${selectedTasks.length} Xong',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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
          onPressed: () => _showAddTaskDialog(context, viewModel),
          backgroundColor: Colors.pinkAccent,
          icon: const Icon(Icons.add_circle, color: Colors.white, size: 28),
          label: const Text('Thêm Mới', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
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
                  child: const Text('Đóng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, TaskViewModel viewModel) {
    final TextEditingController timeController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Thêm công việc mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian (*)',
                        hintText: 'Chọn thời gian',
                        suffixIcon: Icon(Icons.access_time, color: Colors.orangeAccent),
                        border: OutlineInputBorder(),
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
                      decoration: const InputDecoration(
                        labelText: 'Tên công việc (*)',
                        hintText: 'VD: Tập thể dục 30p',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Chi tiết (Tùy chọn)',
                        hintText: 'VD: Chạy bộ quanh công viên...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                FilledButton(
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
                  child: const Text('Thêm'),
                ),
              ],
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF141C5A)),
                  const SizedBox(width: 8),
                  const Text('Trợ lý AI'),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isListening ? Icons.mic : Icons.mic_none, 
                               color: isListening ? Colors.red : Colors.grey),
                    onPressed: () async {
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
                                // Move cursor to end
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
                  ),
                ],
              ),
              content: TextField(
                controller: aiController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Nhập text hoặc bấm Mic để nói...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    speech.stop();
                    Navigator.pop(context);
                  },
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (aiController.text.isNotEmpty) {
                      final text = aiController.text;
                      speech.stop();
                      Navigator.pop(context);
                      await viewModel.generateTasksWithAI(text);
                    }
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Tạo Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
