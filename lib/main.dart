import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_assistant/screens/assistant_home_screen.dart';
import 'package:voice_assistant/services/assistant_controller.dart';
import 'package:voice_assistant/services/assistant_platform.dart';
import 'package:voice_assistant/services/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SettingsRepository(await SharedPreferences.getInstance());
  final controller = AssistantController(
    repository,
    repository.load(),
    MethodChannelAssistantPlatform(),
  );
  await controller.initializeNativeBridge();
  runApp(AssistantApp(controller: controller));
}

class AssistantApp extends StatelessWidget {
  const AssistantApp({super.key, required this.controller});
  final AssistantController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: controller.settings.assistantName,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff6955d9),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff101018),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff1b1b28),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: AssistantHomeScreen(controller: controller),
  );
}
