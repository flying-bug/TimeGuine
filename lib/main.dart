import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'repositories/task_repository.dart';
import 'services/ai_service.dart';
import 'viewmodels/task_viewmodel.dart';
import 'views/splash_screen.dart';
import 'services/notification_service.dart';
import 'viewmodels/settings_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  
  // Request permissions asynchronously without blocking the app startup
  NotificationService().requestPermissions();

  // Dependency Injection (Dependency Inversion Principle)
  // Khởi tạo các interface thay vì implement trực tiếp trong UI
  final ITaskRepository taskRepository = InMemoryTaskRepository();
  
  // Dễ dàng thay đổi Mock AIService thành GeminiAIService mà không cần sửa code ViewModel hay UI
  final IAIService aiService = GeminiAIService(apiKey: 'AIzaSyCFBnexbsEWjEwyvoCCSL9WF2ogwsHP2Zo');
  // final IAIService aiService = MockAIService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskViewModel(
            repository: taskRepository,
            aiService: aiService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(),
        ),
      ],
      child: const AIMateApp(),
    ),
  );
}

class AIMateApp extends StatelessWidget {
  const AIMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    
    return MaterialApp(
      title: 'TimeGenie',
      debugShowCheckedModeBanner: false,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF141C5A), // Navy Blue from logo
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF141C5A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
